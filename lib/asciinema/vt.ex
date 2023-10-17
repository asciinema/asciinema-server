defmodule Asciinema.Vt do
  use Rustler, otp_app: :asciinema, crate: :vt_nif

  def with_vt(cols, rows, opts \\ [], f) do
    resizable = Keyword.get(opts, :resizable, true)
    scrollback_limit = Keyword.get(opts, :scrollback_limit, 100)

    with {:ok, vt} <- new(cols, rows, resizable, scrollback_limit), do: f.(vt)
  end

  # When NIF is loaded, it will override following functions.

  @spec new(integer, integer, boolean, integer | nil) ::
          {:ok, reference} | {:error, :invalid_size}
  def new(_cols, _rows, _resizable, _scrollback_limit), do: :erlang.nif_error(:nif_not_loaded)

  @spec feed(reference, binary) :: {integer, integer} | nil
  def feed(_vt, _str), do: :erlang.nif_error(:nif_not_loaded)

  @spec dump(reference) :: binary
  def dump(_vt), do: :erlang.nif_error(:nif_not_loaded)

  @spec dump_screen(reference) :: {:ok, {list(list({binary, map})), {integer, integer} | nil}}
  def dump_screen(_vt), do: :erlang.nif_error(:nif_not_loaded)

  @spec text(reference) :: binary
  def text(_vt), do: :erlang.nif_error(:nif_not_loaded)
end
