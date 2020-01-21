defmodule Chain do
  @moduledoc """
  Chain is inspired by the Railway programming and JavaScript well known Promise API.

  Its purpose is to ease the construction of multi-step data processing in a more readable manner than using elixir
  native `with` macro.

  Chain is more flexible than a `with` macro  as the error recovery can be placed where you want.
  Chains can be passed as parameters like `Ecto.Multi` objects, and called once (synchronously) using `&Chain.run/1`
  A Chain is composed of steps, that are run only when Chain.run(chain) is called.


  A step can be of three types :
   - next: a step that represents the happy path, it receives the previous result that was a success.
    i.e. either a {:ok, result} or anything that is not {:error, reason}. It receives the unwrapped result
    (not {:ok, result}) as only argument.

   - recover: a step that a standard deviance from the happy path, it receives the previous result that was an error.
    i.e. a {:error, reason} tuple.  It receives the unwrapped reason (not {:error, reason}) as only argument.

   - capture: a step that an unexpected deviance from the happy path. Useful in only special cases. (equivalent to try / rescue)
    It receives the error that was raised in any previous step, and if the function is of arity 2, also the stacktrace.
  """

  defstruct initial_value: nil,
            options: nil,
            steps: []

  @doc """
  Initialize a new Chain with an initial value and options for the chain execution.
  To add success steps to the chain call `&Chain.next/2`
  To add recover steps to the chain call `&Chain.recover/2`
  To add capture steps to the chain call `&Chain.capture/2`

  The result wil be automatically wrapped in a `{:ok, value}` if the result is neither `{:ok, value}` nor
  `{:error, reason}`.

  If the initial value is either a `value` or `{:ok, value}`, it will go the nearest next step.
  If the initial value is `{:error, reason}` then the `reason` will be passed to the next recover step.
  """
  def new(initial_value \\ nil, opts \\ []) do
    %Chain{initial_value: initial_value, options: opts}
  end

  @doc """
  Adds a step to the chain.

  A next step is a function of arity 1
  It takes the result of the previous steps as parameter, and its result will be the parameter of the following step.
  """
  def next(%Chain{} = chain, function) when is_function(function, 1) do
    new_step = Chain.Step.new_success_step(function)
    %Chain{chain | steps: [new_step | chain.steps]}
  end

  @doc """
  Adds a recover step to the chain.

  A recover step is a function of arity 1
  """
  def recover(%Chain{} = chain, function) when is_function(function, 1) do
    new_step = Chain.Step.new_recover_step(function)
    %Chain{chain | steps: [new_step | chain.steps]}
  end

  @doc """
  Adds a capture step to the chain.

  A capture step is a function of arity 1 or 2.
  If the function is of arity 1, it receives the error that was raised, if the arity is 2
  the function receives the raised error and the stacktrace captured when the error was raised.
  """
  def capture(%Chain{} = chain, function)
      when is_function(function, 1) or is_function(function, 2) do
    new_step = Chain.Step.new_capture_step(function)
    %Chain{chain | steps: [new_step | chain.steps]}
  end

  @doc """
  Executes the chain.
  Returns the result from the last function executed.
  (either a `{:ok, value}` or a `{:error, reason}` if a failure was not recovered)
  """
  def run(%Chain{} = chain) do
    chain.steps
    |> Enum.reverse()
    |> Enum.reduce(normalize_result(chain.initial_value), &run_step/2)
    |> manage_raised_error_case()
  end

  defp manage_raised_error_case({:ok, result}), do: {:ok, result}
  defp manage_raised_error_case({:error, reason}), do: {:error, reason}

  defp manage_raised_error_case({:raised_error, error, stacktrace}),
    do: reraise(error, stacktrace)

  defp run_step(%Chain.Step{} = step, previous_result) do
    success_type = Chain.Step.success_type()
    recover_type = Chain.Step.recover_type()
    capture_type = Chain.Step.capture_type()

    case {step.type, previous_result} do
      {^success_type, {:ok, value}} ->
        run_step_function(step, value)

      {^recover_type, {:error, reason}} ->
        run_step_function(step, reason)

      {^capture_type, {:raised_error, error, stacktrace}} ->
        run_capture_step_function(step, error, stacktrace)

      _ ->
        previous_result
    end
  end

  defp run_step_function(step, value) do
    try do
      step.function.(value)
      |> normalize_result()
    rescue
      e -> {:raised_error, e, __STACKTRACE__}
    end
  end

  defp run_capture_step_function(step, error, stacktrace) do
    {:arity, arity} = Function.info(step.function, :arity)

    try do
      case arity do
        1 -> step.function.(error)
        2 -> step.function.(error, stacktrace)
      end
      |> normalize_result()
    rescue
      e -> {:raised_error, e, __STACKTRACE__}
    end
  end

  defp normalize_result(result) do
    case result do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, reason}
      {:raised_error, error, stacktrace} -> {:raised_error, error, stacktrace}
      %Chain{} = chain -> Chain.run(chain)
      value -> {:ok, value}
    end
  end
end
