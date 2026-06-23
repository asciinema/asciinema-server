defmodule Asciinema.SentryFilterTest do
  use ExUnit.Case, async: true
  alias Asciinema.SentryFilter

  defp event(exception) do
    %Sentry.Event{
      event_id: "test",
      timestamp: "2026-01-01T00:00:00",
      original_exception: exception
    }
  end

  describe "before_send/1" do
    test "drops 4xx client-error exceptions" do
      assert SentryFilter.before_send(event(%Plug.CSRFProtection.InvalidCSRFTokenError{})) == nil
      assert SentryFilter.before_send(event(%Plug.BadRequestError{})) == nil
      assert SentryFilter.before_send(event(%Plug.TimeoutError{})) == nil
    end

    test "keeps 5xx and non-Plug exceptions" do
      assert %Sentry.Event{} = SentryFilter.before_send(event(%RuntimeError{message: "boom"}))
    end

    test "keeps events without an exception (e.g. captured messages)" do
      assert %Sentry.Event{} = SentryFilter.before_send(event(nil))
    end
  end
end
