defmodule Chain.Step do
  @moduledoc false

  alias __MODULE__

  @success_type :success
  @recover_type :recover

  defstruct [:type, :function]

  def new_success_step(function) do
    %Step{type: @success_type, function: function}
  end

  def new_recover_step(function) do
    %Step{type: @recover_type, function: function}
  end

  def is_success?(%Step{type: type}), do: type == @success_type
  def is_recover?(%Step{type: type}), do: type == @recover_type
end
