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
end
