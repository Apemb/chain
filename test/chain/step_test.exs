defmodule Chain.StepTest do
  use ExUnit.Case

  alias Chain.Step

  setup do
  a_function = fn _ -> nil end
  %{a_function: a_function}
  end

  test "given a success step, is_success? return true", %{a_function: a_function} do
    # Arrange
    step = Step.new_success_step(a_function)

    # Assert
    assert Step.is_success?(step)
  end

  test "given a recover step, is_success? return false", %{a_function: a_function} do
    # Arrange
    step = Step.new_recover_step(a_function)

    # Assert
    refute Step.is_success?(step)
  end

  test "given a success step, is_recover? return false", %{a_function: a_function} do
    # Arrange
    step = Step.new_success_step(a_function)

    # Assert
    refute Step.is_recover?(step)
  end

  test "given a recover step, is_recover? return true", %{a_function: a_function} do
    # Arrange
    step = Step.new_recover_step(a_function)

    # Assert
    assert Step.is_recover?(step)
  end
end
