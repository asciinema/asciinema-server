defmodule Asciinema.Mixfile do
  use Mix.Project

  def project do
    [app: :asciinema,
     version: "0.0.1",
     elixir: "~> 1.6",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps()]
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
      {:bamboo, "~> 0.8"},
      {:bamboo_smtp, "~> 1.4"},
      {:briefly, "~> 0.3"},
      {:cowboy, "~> 1.0"},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false},
      {:ex_aws, "~> 1.0"},
      {:ex_machina, "~> 2.1", only: :test},
      {:exq, "~> 0.9.0"},
      {:exq_ui, "~> 0.9.0"},
      {:gettext, "~> 0.11"},
      {:html_sanitize_ex, "~> 1.3"},
      {:inflex, "~> 1.9"},
      {:jason, "~> 1.1"},
      {:phoenix, "~> 1.3.4"},
      {:phoenix_ecto, "~> 3.4"},
      {:phoenix_html, "~> 2.12"},
      {:phoenix_live_reload, "~> 1.1", only: :dev},
      {:phoenix_markdown, "~> 0.1"},
      {:phoenix_pubsub, "~> 1.1"},
      {:plug_rails_cookie_session_store, "~> 0.1"},
      {:poison, "~> 3.1"},
      {:poolboy, "~> 1.5"},
      {:postgrex, ">= 0.0.0"},
      {:redix, ">= 0.6.1"},
      {:scrivener_ecto, "~> 1.0"},
      {:scrivener_html, "~> 1.7"},
      {:sentry, "~> 6.4"},
      {:timex, "~> 3.0"},
      {:timex_ecto, "~> 3.0"},
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
     "test": ["ecto.create --quiet", "ecto.migrate", "test"]]
  end
end
