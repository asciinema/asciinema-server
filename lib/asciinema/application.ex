defmodule Asciinema.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    :ok = Oban.Telemetry.attach_default_logger()
    :ok = Asciinema.ObanErrorReporter.configure()

    # List all child processes to be supervised
    children = [
      # Start telemetry reporters
      Asciinema.Telemetry,
      # Start the Ecto repository
      Asciinema.Repo,
      # Start the endpoint when the application starts
      AsciinemaWeb.Endpoint,
      # Start Phoenix PubSub
      {Phoenix.PubSub, [name: Asciinema.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start PNG generator poolboy pool
      :poolboy.child_spec(:worker, Asciinema.PngGenerator.Rsvg.poolboy_config(), []),
      # Start Oban
      {Oban, oban_config()}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Asciinema.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp oban_config do
    Application.fetch_env!(:asciinema, Oban)
  end
end
