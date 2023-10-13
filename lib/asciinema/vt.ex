defmodule Asciinema.Vt do
  use Rustler, otp_app: :asciinema, crate: :vt_nif

  def with_vt(width, height, f) do
    with {:ok, vt} <- new(width, height), do: f.(vt)
  end

  # When NIF is loaded, it will override following functions.

  @spec new(integer, integer) :: {:ok, reference} | {:error, :invalid_size}
  def new(_cols, _rows), do: :erlang.nif_error(:nif_not_loaded)

  @spec feed(reference, binary) :: {integer, integer} | nil
  def feed(_vt, _str), do: :erlang.nif_error(:nif_not_loaded)

  @spec dump(reference) :: binary
  def dump(_vt), do: :erlang.nif_error(:nif_not_loaded)

  @spec dump_screen(reference) :: {:ok, {list(list({binary, map})), {integer, integer} | nil}}
  def dump_screen(_vt), do: :erlang.nif_error(:nif_not_loaded)

  @spec text(reference) :: list(binary)
  def text(_vt), do: :erlang.nif_error(:nif_not_loaded)
end
