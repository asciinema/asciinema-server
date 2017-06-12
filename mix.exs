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
    [mod: {Asciinema, []},
     applications: [
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
       :timex,
       :timex_ecto,
     ]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:briefly, "~> 0.3"},
      {:cowboy, "~> 1.0"},
      {:ex_aws, "~> 1.0"},
      {:gettext, "~> 0.11"},
      {:phoenix, "~> 1.2.1"},
      {:phoenix_ecto, "~> 3.0"},
      {:phoenix_html, "~> 2.6"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:phoenix_markdown, "~> 0.1"},
      {:phoenix_pubsub, "~> 1.0"},
      {:plug_rails_cookie_session_store, "~> 0.1"},
      {:plugsnag, "~> 1.3.0", github: "sickill/plugsnag"},
      {:poison, "~> 2.2"},
      {:poolboy, "~> 1.5"},
      {:porcelain, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
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
