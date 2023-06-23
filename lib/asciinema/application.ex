defmodule Asciinema.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = Oban.Telemetry.attach_default_logger()
    :ok = Asciinema.ObanErrorReporter.configure()

    # List all child processes to be supervised
    children = [
      # Start telemetry reporters
      Asciinema.Telemetry,
      # Start the Ecto repository
      Asciinema.Repo,
      # Start rate limiter
      {PlugAttack.Storage.Ets, name: AsciinemaWeb.PlugAttack.Storage, clean_period: 60_000},
      # Start the endpoint when the application starts
      AsciinemaWeb.Endpoint,
      # Start Phoenix PubSub
      {Phoenix.PubSub, [name: Asciinema.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start PNG generator poolboy pool
      :poolboy.child_spec(:worker, Asciinema.PngGenerator.Rsvg.poolboy_config(), []),
      # Start Oban
      {Oban, oban_config()},
      {Registry, [keys: :unique, name: Asciinema.Streaming.LiveStreamRegistry]},
      {Registry,
       [
         keys: :duplicate,
         name: Asciinema.Streaming.PubSubRegistry,
         partitions: System.schedulers_online()
       ]},
      Asciinema.Streaming.LiveStreamSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Asciinema.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    AsciinemaWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp oban_config do
    Application.fetch_env!(:asciinema, Oban)
  end
end
