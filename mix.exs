defmodule Asciinema.MixProject do
  use Mix.Project

  def project do
    [
      app: :asciinema,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: Mix.compilers(),
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
      extra_applications: [:logger, :runtime_tools]
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
      {:bamboo, "~> 2.2"},
      {:bamboo_phoenix, "~> 1.0"},
      {:bamboo_smtp, "~> 4.2"},
      {:briefly, "~> 0.3"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.4"},
      {:ecto_sql, "~> 3.6"},
      {:ex_aws, "~> 2.2"},
      {:ex_aws_s3, "~> 2.1"},
      {:ex_machina, "~> 2.4", only: :test},
      {:gettext, "~> 0.18"},
      {:hackney, "~> 1.18"},
      {:html_sanitize_ex, "~> 1.4"},
      {:inflex, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:oban, "~> 2.14"},
      # override for scrivener_html
      {:phoenix, "~> 1.6.15", override: true},
      {:phoenix_ecto, "~> 4.4"},
      # override for scrivener_html
      {:phoenix_html, "~> 3.3", override: true},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18.14"},
      {:phoenix_markdown, "~> 1.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:plug_attack, "~> 0.4.3"},
      {:plug_cowboy, "~> 2.5"},
      {:poolboy, "~> 1.5"},
      {:postgrex, ">= 0.0.0"},
      {:remote_ip, "~> 1.1"},
      {:rustler, "~> 0.27.0"},
      {:scrivener_ecto, "~> 2.4"},
      {:scrivener_html, "~> 1.8"},
      {:sentry, "~> 8.0"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_metrics_prometheus, "~> 1.1"},
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
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
