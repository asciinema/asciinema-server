defmodule Asciinema.Upgrades.Worker do
  defmacro __using__(_) do
    quote do
      use Oban.Worker,
        queue: :upgrades,
        unique: [period: :infinity, states: [:available, :scheduled, :executing]]
    end
  end
end
