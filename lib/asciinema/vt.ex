defmodule Asciinema.Vt do
  use Rustler, otp_app: :asciinema, crate: :vt

  # When NIF is loaded, it will override following functions.

  @spec new(integer, integer, integer | nil) :: {:ok, reference} | {:error, :invalid_size}
  def new(_cols, _rows, _scrollback_limit), do: :erlang.nif_error(:nif_not_loaded)

  @spec feed(reference, binary) :: :ok
  def feed(_vt, _str), do: :erlang.nif_error(:nif_not_loaded)

  @spec resize(reference, integer, integer) :: :ok
  def resize(_vt, _cols, _rows), do: :erlang.nif_error(:nif_not_loaded)

  @spec dump(reference) :: binary
  def dump(_vt), do: :erlang.nif_error(:nif_not_loaded)

  @spec dump_screen(reference) :: {list(list({binary, map})), {integer, integer} | nil}
  def dump_screen(_vt), do: :erlang.nif_error(:nif_not_loaded)

  @spec text(reference) :: binary
  def text(_vt), do: :erlang.nif_error(:nif_not_loaded)
end
