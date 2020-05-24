defmodule Asciinema.Mixfile do
  use Mix.Project

  def project do
    [
      app: :asciinema,
      version: "0.0.1",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
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
    [mod: {Asciinema.Application, []},
     extra_applications: [:logger]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:bamboo, "~> 1.2"},
      {:bamboo_smtp, "~> 1.6"},
      {:briefly, "~> 0.3"},
      {:credo, "~> 1.4", only: [:dev, :test], runtime: false},
      {:earmark, "~> 1.4"},
      {:ecto_sql, "~> 3.0"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:ex_machina, "~> 2.4", only: :test},
      {:exq, "~> 0.13.5"},
      {:exq_ui, "~> 0.11.0"},
      {:gettext, "~> 0.18"},
      {:html_sanitize_ex, "~> 1.4"},
      {:inflex, "~> 2.0"},
      {:jason, "~> 1.2"},
      {:phoenix, "~> 1.4.17"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 2.14"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_markdown, "~> 1.0"},
      {:phoenix_pubsub, "~> 1.1"},
      {:plug_cowboy, "~> 2.2"},
      {:poolboy, "~> 1.5"},
      {:postgrex, ">= 0.0.0"},
      {:quantum, "~> 2.4"},
      {:redix, "~> 0.10.7"},
      {:scrivener_ecto, "~> 2.4"},
      {:scrivener_html, "~> 1.8"},
      {:sentry, "~> 7.2"},
      {:timex, "~> 3.6"},
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to create, migrate and run the seeds file at once:
  #
  #     $ mix ecto.setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    ["ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
     "ecto.reset": ["ecto.drop", "ecto.setup"],
     test: ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
