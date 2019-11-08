defmodule Chain do
  @moduledoc """
  Chain is inspired by the Railway programming and JavaScript well known Promise API.

  Its purpose is to ease the construction of multi-step data processing in a more readable manner than using elixir
  native `with` macro.

  Chain is more flexible than a `with` macro  as the error recovery can be placed where you want.
  Chains can be passed as parameters like `Ecto.Multi` objects, and called once (synchronously) using `&Chain.run/1`
  """

  defstruct initial_value: nil,
            options: nil,
            steps: []

  @doc """
  Initialize a new Chain with an initial value and options for the chain execution.
  To add success steps to the chain call `&Chain.next/2`
  To add recover steps to the chain call `&Chain.recover/2`

  The result wil be automatically wrapped in a `{:ok, value}` if the result is neither `{:ok, value}` nor
  `{:error, reason}`.

  If the initial value is either a `value` or `{:ok, value}`, it will go the nearest next step.
  If the initial value is `{:error, reason}` then the `reason` will be passed to the next recover step.
  """
  def new(initial_value \\ nil, opts \\ []) do
    %Chain{initial_value: initial_value, options: opts}
  end

  # TODO: verify function is a function and that arity is of 1
  # TODO: add possibility of returning a `%Chain{}` as result and that the steps will be inserted in the chain
  @doc """
  Adds a step to the chain.
  A step is a function of arity 1

  It takes the result of the previous steps as parameter, and its result will be the parameter of the following step.
  """
  def next(%Chain{} = chain, function) when is_function(function, 1) do
    new_step = Chain.Step.new_success_step(function)
    %Chain{chain | steps: [new_step | chain.steps]}
  end

  @doc """
  Adds a recover step to the chain.
  """
  def recover(%Chain{} = chain, function) when is_function(function, 1) do
    new_step = Chain.Step.new_recover_step(function)
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
  end

  defp run_step(%Chain.Step{} = step, previous_result) do
    is_success_step = Chain.Step.is_success?(step)
    is_recover_step = Chain.Step.is_recover?(step)

    case {is_success_step, is_recover_step, previous_result} do
      {true, false, {:ok, value}} ->
        step.function.(value)
        |> normalize_result()

      {false, true, {:error, value}} ->
        step.function.(value)
        |> normalize_result()

      _ ->
        previous_result
    end
  end

  defp normalize_result(result) do
    case result do
      {:ok, value} -> {:ok, value}
      {:error, reason} -> {:error, reason}
      %Chain{} = chain -> Chain.run(chain)
      value -> {:ok, value}
    end
  end
end
