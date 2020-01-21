defmodule Chain.Step do
  @moduledoc false

  alias __MODULE__

  @success_type :success
  @recover_type :recover
  @capture_type :capture

  defstruct [:type, :function]

  def new_success_step(function) do
    %Step{type: @success_type, function: function}
  end

  def new_recover_step(function) do
    %Step{type: @recover_type, function: function}
  end

  def new_capture_step(function) do
    %Step{type: @capture_type, function: function}
  end

  def success_type, do: @success_type
  def recover_type, do: @recover_type
  def capture_type, do: @capture_type

  def is_success?(%Step{type: type}), do: type == @success_type
  def is_recover?(%Step{type: type}), do: type == @recover_type
  def is_capture?(%Step{type: type}), do: type == @capture_type
end
