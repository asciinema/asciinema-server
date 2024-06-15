defmodule Asciinema.MixProject do
  use Mix.Project

  def project do
    [
      app: :asciinema,
      version: "1.0.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        asciinema: [
          config_providers: [
            {Config.Reader, {:system, "RELEASE_ROOT", "/etc/custom.exs"}}
          ]
        ]
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Asciinema.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:briefly, "~> 0.3"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.4"},
      {:ecto_psql_extras, "~> 0.7.14"},
      {:ecto_sql, "~> 3.6"},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, "~> 2.1"},
      {:ex_machina, "~> 2.4", only: :test},
      {:gen_smtp, "~> 1.2"},
      {:gettext, "~> 0.20"},
      {:hackney, "~> 1.18"},
      {:horde, "~> 0.8.7"},
      {:html_sanitize_ex, "~> 1.4"},
      {:identicon_svg, "~> 0.9.2"},
      {:inflex, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:libcluster, "~> 3.3"},
      {:mix_test_watch, "~> 1.2", only: :dev, runtime: false},
      {:oban, "~> 2.17"},
      # override for scrivener_html
      {:phoenix, "~> 1.7.11", override: true},
      {:phoenix_ecto, "~> 4.5.1"},
      # override for scrivener_html
      {:phoenix_view, "~> 2.0.3"},
      {:phoenix_html, "~> 3.3.3", override: true},
      {:phoenix_live_dashboard, "~> 0.8.3"},
      {:phoenix_live_reload, "~> 1.5", only: :dev},
      {:phoenix_live_view, "~> 0.20.13"},
      {:phoenix_markdown, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.1.3"},
      {:plug_attack, "~> 0.4.3"},
      {:plug_cowboy, "~> 2.5"},
      {:poolboy, "~> 1.5"},
      {:postgrex, ">= 0.0.0"},
      {:remote_ip, "~> 1.1"},
      {:rustler, "~> 0.27.0"},
      {:scrivener_ecto, "~> 2.4"},
      {:scrivener_html, "~> 1.8"},
      {:sentry, "~> 8.0"},
      {:swoosh, "~> 1.16"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:timex, "~> 3.7"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
