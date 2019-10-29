defmodule ChainTest do
  use ExUnit.Case
  doctest Chain

  test """
  with a new chain, then executes the function receiving the initial value as argument
  and passing the result to the next function
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
  with a chain of function, when a steps returns {:error, reason}
  then skips to next recover step
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
        flunk("Should not pass in then step")
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
  given a chain of function, when a steps does not return {:ok, _} or {:error, _}
  then value is considered a success and passed to next step
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
end
