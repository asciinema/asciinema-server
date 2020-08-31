defmodule Asciinema.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec

    # List all child processes to be supervised
    children = [
      # Start the Ecto repository
      Asciinema.Repo,
      # Start the endpoint when the application starts
      AsciinemaWeb.Endpoint,
      # Start PNG generator poolboy pool
      :poolboy.child_spec(:worker, Asciinema.PngGenerator.Rsvg.poolboy_config(), []),
      # Start Exq workers
      supervisor(Exq, []),
      # Start cron job scheduler
      Asciinema.Scheduler
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Asciinema.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
