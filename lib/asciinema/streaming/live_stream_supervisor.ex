defmodule Asciinema.Streaming.LiveStreamSupervisor do
  use DynamicSupervisor
  alias Asciinema.Streaming.LiveStreamServer
  require Logger

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(id) do
    Logger.debug("stream sup: starting server for live stream #{id}")
    DynamicSupervisor.start_child(__MODULE__, {LiveStreamServer, id})
  end

  def ensure_child(id) do
    case start_child(id) do
      {:error, {:already_started, pid}} ->
        Logger.debug("stream sup: server already exists for live stream #{id}")
        {:ok, pid}

      otherwise ->
        otherwise
    end
  end
end
