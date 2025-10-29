defmodule Asciinema.Fts do
  use Rustler, otp_app: :asciinema, crate: :fts

  # When NIF is loaded, it will override following functions.

  @spec new(integer, integer) :: {:ok, reference} | {:error, :invalid_size}
  def new(_cols, _rows), do: :erlang.nif_error(:nif_not_loaded)

  @spec feed(reference, binary) :: :ok
  def feed(_fts, _str), do: :erlang.nif_error(:nif_not_loaded)

  @spec resize(reference, integer, integer) :: :ok
  def resize(_fts, _cols, _rows), do: :erlang.nif_error(:nif_not_loaded)

  @spec dump(reference) :: binary
  def dump(_fts), do: :erlang.nif_error(:nif_not_loaded)
end
