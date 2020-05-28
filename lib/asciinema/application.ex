defmodule Asciinema.Application do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Asciinema.Repo, []),
      # Start the endpoint when the application starts
      supervisor(AsciinemaWeb.Endpoint, []),
      # Start your own worker by calling: Asciinema.Worker.start_link(arg1, arg2, arg3)
      # worker(Asciinema.Worker, [arg1, arg2, arg3]),
      :poolboy.child_spec(:worker, Asciinema.PngGenerator.Rsvg.poolboy_config(), []),
      supervisor(Exq, []),
      Asciinema.Scheduler
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Asciinema.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
