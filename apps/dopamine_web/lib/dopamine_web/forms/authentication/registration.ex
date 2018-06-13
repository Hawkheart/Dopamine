defmodule DopamineWeb.Forms.Registration do
  defstruct auth: %{}


  def from_map(in_map = %{}) do
    {:error, :bad}
  end
end
