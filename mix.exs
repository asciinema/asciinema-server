defmodule Asciinema.Mixfile do
  use Mix.Project

  def project do
    [app: :asciinema,
     version: "0.0.1",
     elixir: "~> 1.2",
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
     applications: [
       :bamboo,
       :bamboo_smtp,
       :briefly,
       :bugsnag,
       :cowboy,
       :ex_aws,
       :gettext,
       :logger,
       :phoenix,
       :phoenix_ecto,
       :phoenix_html,
       :phoenix_pubsub,
       :plug_rails_cookie_session_store,
       :poolboy,
       :porcelain,
       :postgrex,
       :redix,
       :timex,
       :timex_ecto,
       :exq,
       :exq_ui,
     ]]
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
      {:bamboo_smtp, "~> 1.4.0"},
      {:briefly, "~> 0.3"},
      {:bugsnag, "~> 1.5.0"},
      {:cowboy, "~> 1.0"},
      {:credo, "~> 0.8", only: [:dev, :test], runtime: false},
      {:ex_aws, "~> 1.0"},
      {:exq, "~> 0.9.0"},
      {:exq_ui, "~> 0.9.0"},
      {:gettext, "~> 0.11"},
      {:phoenix, "~> 1.3.0"},
      {:phoenix_ecto, "~> 3.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:phoenix_markdown, "~> 0.1"},
      {:phoenix_pubsub, "~> 1.0"},
      {:plug_rails_cookie_session_store, "~> 0.1"},
      {:plugsnag, "~> 1.3.0", github: "sickill/plugsnag"},
      {:poison, "~> 2.2"},
      {:poolboy, "~> 1.5"},
      {:porcelain, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:redix, ">= 0.6.1"},
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
