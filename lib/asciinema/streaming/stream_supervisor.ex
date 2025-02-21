defmodule Asciinema.Streaming.StreamSupervisor do
  use DynamicSupervisor
  alias Asciinema.Streaming.StreamServer
  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(id) do
    Logger.debug("stream sup: starting server for stream #{id}")
    DynamicSupervisor.start_child(__MODULE__, {StreamServer, id})
  end

  def ensure_child(id) do
    case start_child(id) do
      {:error, {:already_started, pid}} ->
        Logger.debug("stream sup: server already exists for stream #{id}")
        {:ok, pid}

      otherwise ->
        otherwise
    end
  end
end
