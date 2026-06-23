defmodule Asciinema.SentryFilter do
  @moduledoc """
  Sentry `:before_send` callback that drops expected client-error (4xx)
  exceptions, so only actual server faults (5xx) get reported. It runs for
  every captured event regardless of source (web requests, Oban jobs, logged
  crashes); non-HTTP exceptions have no `plug_status`, resolve to 500, and are
  kept.
  """

  def before_send(%Sentry.Event{original_exception: exception} = event) do
    if client_error?(exception), do: nil, else: event
  end

  defp client_error?(nil), do: false
  defp client_error?(exception), do: Plug.Exception.status(exception) in 400..499
end
