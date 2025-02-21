defmodule Asciinema.OnExit do
  defmacro __using__(_) do
    quote do
      def on_exit_restore_config(module) do
        config = Application.get_env(:asciinema, module, [])
        on_exit(fn -> Application.put_env(:asciinema, module, config) end)
      end
    end
  end
end
