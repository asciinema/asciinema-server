defmodule Asciinema.Vt do
  use Rustler, otp_app: :asciinema, crate: :vt_nif

  def with_vt(width, height, f) do
    with {:ok, vt} <- new(width, height), do: f.(vt)
  end

  # When NIF is loaded, it will override following functions.

  def new(_width, _height), do: :erlang.nif_error(:nif_not_loaded)
  # => {:ok, vt} | {:error, :invalid_size}

  def feed(_vt, _str), do: :erlang.nif_error(:nif_not_loaded)
  # => nil | {cols, rows}

  def dump(_vt), do: :erlang.nif_error(:nif_not_loaded)
  # => ...

  def dump_screen(_vt), do: :erlang.nif_error(:nif_not_loaded)
  # => {:ok, {lines, cursor}}

  def text(_vt), do: :erlang.nif_error(:nif_not_loaded)
  # => ...
end
