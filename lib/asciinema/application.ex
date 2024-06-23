defmodule Asciinema.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    :ok = Oban.Telemetry.attach_default_logger()
    :ok = Asciinema.ObanErrorReporter.configure()

    topologies = Application.get_env(:libcluster, :topologies, [])

    # List all child processes to be supervised
    children = [
      # Start task supervisor
      {Task.Supervisor, name: Asciinema.TaskSupervisor},
      # Start cluster supervisor
      {Cluster.Supervisor, [topologies, [name: Asciinema.ClusterSupervisor]]},
      # Start the PubSub system
      {Phoenix.PubSub, [name: Asciinema.PubSub, adapter: Phoenix.PubSub.PG2]},
      # Start live stream viewer tracker
      {Asciinema.Streaming.ViewerTracker, [pubsub_server: Asciinema.PubSub]},
      # Start telemetry reporters
      Asciinema.Telemetry,
      # Start the Ecto repository
      Asciinema.Repo,
      # Start PNG generator poolboy pool
      :poolboy.child_spec(:worker, Asciinema.PngGenerator.Rsvg.poolboy_config(), []),
      # Start Oban
      {Oban, oban_config()},
      # Start distributed registry
      {Horde.Registry,
       [name: Asciinema.Streaming.LiveStreamRegistry, keys: :unique, members: :auto]},
      Asciinema.Streaming.LiveStreamSupervisor,
      # Start rate limiter
      {PlugAttack.Storage.Ets, name: AsciinemaWeb.PlugAttack.Storage, clean_period: 60_000},
      # Start the public endpoint
      {AsciinemaWeb.Endpoint, endpoint_config()},
      # Start the admin endpoint
      AsciinemaWeb.Admin.Endpoint
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

  defp endpoint_config do
    defaults = take_app_env(AsciinemaWeb.Endpoint)

    http = put_option([], :port, "PORT", &String.to_integer/1)

    url =
      []
      |> put_option(:scheme, "URL_SCHEME")
      |> put_option(:host, "URL_HOST")
      |> put_option(:port, "URL_PORT", &String.to_integer/1)
      |> put_option(:path, "URL_PATH")

    url =
      case Keyword.get(url, :scheme) do
        "http" -> Keyword.put_new(url, :port, 80)
        "https" -> Keyword.put_new(url, :port, 443)
        nil -> url
      end

    overrides =
      []
      |> put_option(:server, "PHX_SERVER", fn _ -> true end)
      |> put_option(:secret_key_base, "SECRET_KEY_BASE")
      |> Keyword.merge(http: http, url: url)

    config = deep_merge(defaults, overrides)

    if System.get_env("INSPECT_CONFIG") do
      IO.inspect(config, label: "public endpoint config")
    end

    config
  end

  defp take_app_env(app \\ :asciinema, key) do
    env = Application.get_env(app, key)
    Application.delete_env(app, key)
    Application.put_env(app, key, [])

    env
  end

  defp put_option(opts, key, var, coerce \\ nil, default \\ :none)

  defp put_option(opts, key, var, nil, default),
    do: put_option(opts, key, var, fn value -> value end, default)

  defp put_option(opts, key, var, coerce, default) do
    case System.get_env(var) do
      nil ->
        case default do
          :none -> opts
          value -> Keyword.put(opts, key, value)
        end

      value ->
        Keyword.put(opts, key, coerce.(value))
    end
  end

  def deep_merge(original, overrides) do
    Keyword.merge(original, overrides, &on_conflict/3)
  end

  defp on_conflict(_key, a, b) when is_list(a) and is_list(b), do: deep_merge(a, b)
  defp on_conflict(_key, _a, b), do: b
end
