defmodule Asciinema.AppEnv do
  @moduledoc """
  Application environment wrapper that supports process-local configuration in tests.

  In production, this module delegates to standard Application functions.
  In tests, it uses ProcessTree with Process dictionary to provide process-local 
  configuration that allows tests to modify configuration without affecting other 
  concurrent tests.
  """

  if Mix.env() == :test do
    def get(key, default \\ nil),
      do: ProcessTree.get({:app_env, key}, default: default_value(key, default))

    def put(key, value), do: Process.put({:app_env, key}, value)
  else
    def get(key, default \\ nil), do: default_value(key, default)
  end

  defp default_value(key, default), do: Application.get_env(:asciinema, key, default)
end
