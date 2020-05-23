defmodule Asciinema.Ecto.Type.JsonArray do
  use Ecto.Type

  def type, do: :text

  def cast(any), do: {:ok, any}
  def load(value), do: Jason.decode(value)
  def dump(value), do: Jason.encode(value)
end
