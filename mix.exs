defmodule Asciinema.MixProject do
  use Mix.Project

  def project do
    [
      app: :asciinema,
      version: "1.0.0",
      elixir: "~> 1.19",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix_live_view] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      releases: [
        asciinema: [
          config_providers: [
            {Config.Reader, {:system, "RELEASE_ROOT", "/etc/custom.exs"}}
          ]
        ]
      ]
    ]
  end

  def cli do
    [
      preferred_envs: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Asciinema.Application, []},
      extra_applications: [:logger, :runtime_tools, :os_mon, :inets, :ssl]
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
      {:crontab, "~> 1.2"},
      {:earmark, "~> 1.4.46"},
      {:ecto_psql_extras, "~> 0.8.8"},
      {:ecto_sql, "~> 3.6"},
      {:esbuild, "~> 0.10", runtime: Mix.env() == :dev},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, "~> 2.1"},
      {:ex_machina, "~> 2.4", only: :test},
      {:excoveralls, "~> 0.18", only: :test},
      {:gen_smtp, "~> 1.3"},
      {:gettext, "~> 1.0"},
      {:hackney, "~> 1.18"},
      {:horde, "~> 0.10.0"},
      {:html_sanitize_ex, "~> 1.4"},
      {:identicon_svg, "~> 1.0"},
      {:inflex, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:libcluster, "~> 3.3"},
      {:mix_test_watch, "~> 1.2", only: :dev, runtime: false},
      {:oban, "~> 2.20"},
      {:oban_web, "~> 2.11"},
      {:ok, "~> 2.3"},
      {:phoenix, "~> 1.8.9"},
      {:phoenix_ecto, "~> 4.7"},
      {:phoenix_view, "~> 2.0.3"},
      {:phoenix_html, "~> 4.3"},
      {:phoenix_live_dashboard, "~> 0.8.7"},
      {:phoenix_live_reload, "~> 1.6", only: :dev},
      {:phoenix_live_view, "~> 1.2.7"},
      {:phoenix_pubsub, "~> 2.2"},
      {:phoenix_test, "~> 0.11.1", only: :test},
      {:plug_attack, "~> 0.4.3"},
      {:plug_cowboy, "~> 2.7"},
      {:postgrex, ">= 0.0.0"},
      {:process_tree, "~> 0.3", only: :test},
      {:remote_ip, "~> 1.1"},
      {:rustler, "~> 0.38.0"},
      {:scrivener_ecto, "~> 3.1"},
      {:sentry, "~> 13.3"},
      {:stream_data, "~> 1.0", only: :test},
      {:swoosh, "~> 1.16"},
      {:telemetry_metrics, "~> 1.1"},
      {:telemetry_poller, "~> 1.0"},
      {:tzdata, "~> 1.1"},
      {:uuid, "~> 1.1"}
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
      setup: ["deps.get", "ecto.setup", "assets.setup", "assets.build"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "assets.setup": [
        "esbuild.install --if-missing"
      ],
      "assets.build": ["esbuild default", "esbuild admin", "esbuild css"],
      "assets.deploy": [
        "esbuild default --minify",
        "esbuild admin --minify",
        "esbuild css --minify",
        "phx.digest"
      ],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
