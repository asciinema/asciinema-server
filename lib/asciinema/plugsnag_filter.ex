defmodule Asciinema.PlugsnagFilter do
  defmacro __using__(_options \\ []) do
    quote location: :keep do
      def handle_errors(_conn, %{reason: %Phoenix.NotAcceptableError{}}) do
        nil
      end
    end
  end
end
