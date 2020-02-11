defmodule ChainTest do
  use ExUnit.Case
  doctest Chain

  test """
  GIVEN a new chain
  WHEN executes the function
  THEN the first step receives the initial value as argument and passes the result to the next function
  """ do
    # Arrange
    initial_value = "initial value"
    return_value = "return value"

    # Act
    chain_result =
      initial_value
      |> Chain.new()
      |> Chain.next(fn value ->
        assert value == initial_value

        {:ok, return_value}
      end)
      |> Chain.next(fn value ->
        assert value == return_value

        {:ok, "success"}
      end)
      |> Chain.run()

    # Assert

    assert {:ok, "success"} == chain_result
  end

  test """
  GIVEN a chain of function
  WHEN a steps returns {:error, reason}
  THEN skips to next recover step
  """ do
    # Arrange
    initial_value = "initial value"
    error_reason = "some error reason"

    # Act
    chain_result =
      initial_value
      |> Chain.new()
      |> Chain.next(fn value ->
        assert value == initial_value

        {:error, error_reason}
      end)
      |> Chain.next(fn _ ->
        flunk("Should not pass in next step")
      end)
      |> Chain.recover(fn reason ->
        assert reason == error_reason

        {:ok, "success"}
      end)
      |> Chain.run()

    # Assert
    assert {:ok, "success"} == chain_result
  end

  test """
  GIVEN a chain of function
  WHEN a steps does not return {:ok, _} or {:error, _}
  THEN value is considered a success and passed to next step
  """ do
    # Arrange
    value = "some value"

    # Act
    chain_result =
      Chain.new()
      |> Chain.next(fn nil -> value end)
      |> Chain.next(fn v ->
        assert v == value

        {:not_normalized, v}
      end)
      |> Chain.run()

    # Assert

    assert chain_result == {:ok, {:not_normalized, value}}
  end

  test """
  GIVEN a chain of function
  WHEN a steps returns another Chain (with ok tuple)
  THEN that Chain is passed as is to the next step
  """ do
    # Arrange
    value = "some value"

    # Act
    chain_result =
      Chain.new()
      |> Chain.next(fn nil ->
        new_chain =
          Chain.new()
          |> Chain.next(fn nil -> value end)

        {:ok, new_chain}
      end)
      |> Chain.next(fn v ->
        assert %Chain{} = v

        :whatever
      end)
      |> Chain.run()

    # Assert
    assert chain_result == {:ok, :whatever}
  end

  test """
  GIVEN a chain of function
  WHEN a steps returns another Chain (with error tuple)
  THEN that Chain is passed as is to the next recover step
  """ do
    # Arrange
    value = "some value"

    # Act
    chain_result =
      Chain.new()
      |> Chain.next(fn nil ->
        new_chain =
          Chain.new()
          |> Chain.next(fn nil -> value end)

        {:error, new_chain}
      end)
      |> Chain.next(fn _ ->
        flunk("Should not pass in next step")
      end)
      |> Chain.recover(fn reason ->
        assert %Chain{} = reason

        {:ok, :whatever}
      end)
      |> Chain.run()

    # Assert
    assert chain_result == {:ok, :whatever}
  end

  test """
  GIVEN a chain of function
  WHEN a steps returns another Chain (plainly without any tuple)
  THEN that Chain is run and its result is passed to the next step
  """ do
    # Arrange
    value = "some value"
    reason = "some reason"

    # Act
    chain_result =
      Chain.new()
      |> Chain.next(fn nil ->
        new_chain_success =
          Chain.new()
          |> Chain.next(fn nil -> value end)

        new_chain_success
      end)
      |> Chain.next(fn v ->
        assert value == v

        new_chain_failure =
          Chain.new()
          |> Chain.next(fn nil -> {:error, reason} end)

        new_chain_failure
      end)
      |> Chain.recover(fn r ->
        assert reason = r

        {:ok, :whatever}
      end)
      |> Chain.run()

    # Assert
    assert chain_result == {:ok, :whatever}
  end

  test """
  GIVEN a chain of function
  WHEN a steps throws an error
  THEN that error can be rescued if a rescue step is present
  """ do
    # Arrange
    error_message = "error message"

    # Act
    chain_result =
      Chain.new()
      |> Chain.next(fn _ -> error_function(error_message) end)
      |> Chain.capture(fn error ->
        {:ok, error}
      end)
      |> Chain.run()

    # Assert
    expected_error = %RuntimeError{message: error_message}
    assert chain_result == {:ok, expected_error}
  end

  test """
  GIVEN a chain of function
  WHEN a steps throws an error
  THEN that error is not rescued if no rescue step is present
  """ do
    # Arrange
    error_message = "error message"

    # Act
    # Assert
    assert_raise RuntimeError, error_message, fn ->
      Chain.new()
      |> Chain.next(fn _ -> error_function(error_message) end)
      |> Chain.run()
    end
  end

  test """
  GIVEN a chain of function
  WHEN a steps throws an error and no rescue step is present
  THEN that error is reraised and stacktrace conserved from initial raise
  """ do
    # Arrange
    error_message = "error message"

    # Act
    try do
      Chain.new()
      |> Chain.next(fn _ -> error_function(error_message) end)
      |> Chain.run()
    rescue
      e ->
        # Assert
        expected_error = %RuntimeError{message: error_message}
        assert e == expected_error

        assert [{ChainTest, :error_function, 1, _} | _] = __STACKTRACE__
    end
  end

  test """
  GIVEN a chain of function
  WHEN a steps throws an error and a rescue step is present
  THEN that stacktrace is given as second arg if capture fun arity is 2
  """ do
    # Arrange
    error_message = "error message"

    # Act
    result =
      Chain.new()
      |> Chain.next(fn _ -> error_function(error_message) end)
      |> Chain.capture(fn e, stacktrace -> {:ok, {e, stacktrace}} end)
      |> Chain.run()

    # Assert
    expected_error = %RuntimeError{message: error_message}
    {:ok, {error, stacktrace}} = result

    assert error == expected_error
    assert [{ChainTest, :error_function, 1, _} | _] = stacktrace
  end

  test """
  GIVEN a chain
  WHEN executes a next_map on an Enum
  THEN returns a list mapped with the function passed to next_map
  """ do
    # Arrange
    initial_values = ["initial 1", "initial 2", "initial 3"]

    # Act
    chain_result =
      initial_values
      |> Chain.new()
      |> Chain.next_map(fn value ->
        assert Enum.member?(initial_values, value)

        return_value = String.replace_prefix(value, "initial", "final")
        {:ok, return_value}
      end)
      |> Chain.run()

    # Assert
    return_values = ["final 1", "final 2", "final 3"]
    assert {:ok, return_values} == chain_result
  end

  test """
  GIVEN a chain
  WHEN executes a next_map on an Enum where an instance of map function fails
  THEN returns a list mapped with the function passed to next_map
  """ do
    # Arrange
    initial_values = ["initial 1", "initial 2", "initial 3"]
    some_error_reason = :not_a_odd_number

    # Act
    chain_result =
      initial_values
      |> Chain.new()
      |> Chain.next_map(fn value ->
        assert Enum.member?(initial_values, value)

        if String.ends_with?(value, "2") do
          {:error, some_error_reason}
        else
          return_value = String.replace_prefix(value, "initial", "final")
          {:ok, return_value}
        end
      end)
      |> Chain.run()

    # Assert
    assert {:error, some_error_reason} == chain_result
  end

  defp error_function(error_message), do: raise(error_message)
end
