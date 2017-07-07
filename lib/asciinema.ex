defmodule Asciinema do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec

    redis_url = Application.get_env(:asciinema, :redis_url)

    # Define workers and child supervisors to be supervised
    children = [
      # Start the Ecto repository
      supervisor(Asciinema.Repo, []),
      # Start the endpoint when the application starts
      supervisor(Asciinema.Endpoint, []),
      # Start your own worker by calling: Asciinema.Worker.start_link(arg1, arg2, arg3)
      # worker(Asciinema.Worker, [arg1, arg2, arg3]),
      :poolboy.child_spec(:worker, Asciinema.PngGenerator.A2png.poolboy_config(), []),
      supervisor(Asciinema.Vt.Pool, []),
      worker(Redix, [redis_url, [name: :redix]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Asciinema.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Asciinema.Endpoint.config_change(changed, removed)
    :ok
  end
end
