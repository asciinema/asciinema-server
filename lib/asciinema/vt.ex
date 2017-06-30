defmodule Asciinema.Vt do
  alias Asciinema.Vt.{Pool, Worker}

  def with_vt(width, height, f) do
    Pool.checkout(fn vt ->
      :ok = new(vt, width, height)
      f.(vt)
    end)
  end

  def new(vt, width, height) do
    Worker.new(vt, width, height)
  end

  def feed(vt, data) do
    Worker.feed(vt, data)
  end

  def dump_screen(vt, timeout \\ 5_000) do
    Worker.dump_screen(vt, timeout)
  end
end
