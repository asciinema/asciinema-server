defmodule Asciinema.Vt.Pool do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [])
  end

  def init([]) do
    Supervisor.init([
      :poolboy.child_spec(:vt_pool, pool_config())
    ], strategy: :one_for_one, name: __MODULE__)
  end

  def checkout(f, timeout \\ 5_000) do
    :poolboy.transaction(:vt_pool, fn worker ->
      try do
        f.(worker)
      catch :exit, reason ->
        Process.exit(worker, :kill)
        case reason do
          {:timeout, _} -> {:error, :timeout}
          _ -> {:error, :unknown}
        end
      end
    end, timeout)
  end

  defp pool_config do
    [name: {:local, :vt_pool},
     worker_module: Asciinema.Vt.Worker,
     size: 2,
     max_overflow: 0]
  end
end
