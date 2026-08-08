defmodule AsciinemaWeb.ApplicationView do
  import Phoenix.Component, only: [sigil_H: 2]
  alias Asciinema.Accounts

  def present?([]), do: false
  def present?(nil), do: false
  def present?(""), do: false
  def present?(_), do: true

  def time_tag(time) do
    assigns = %{
      iso_8601_ts: DateTime.to_iso8601(time),
      rfc_1123_ts: rfc_1123(time)
    }

    ~H|<time datetime={@iso_8601_ts}>on {@rfc_1123_ts}</time>|
  end

  def time_ago_tag(time) do
    assigns = %{
      iso_8601_ts: DateTime.to_iso8601(time),
      rfc_1123_ts: rfc_1123(time),
      from_now: relative_time(time)
    }

    ~H|<time datetime={@iso_8601_ts} title={@rfc_1123_ts}>{@from_now}</time>|
  end

  def rfc_1123(time), do: Calendar.strftime(time, "%a, %d %b %Y %H:%M:%S +0000")

  def relative_time(time) do
    seconds = DateTime.diff(DateTime.utc_now(), time)

    cond do
      seconds < -59 -> "in #{time_span(-seconds)}"
      seconds < 0 -> "in a moment"
      seconds < 60 -> "just now"
      true -> "#{time_span(seconds)} ago"
    end
  end

  # Fixed-size units: a month is 30 days and a year is 12 such months, so
  # every span maps to exactly one unit with no gaps at the boundaries.
  defp time_span(seconds) do
    cond do
      seconds < 3_600 -> pluralize(div(seconds, 60), "minute")
      seconds < 86_400 -> pluralize(div(seconds, 3_600), "hour")
      seconds < 2_592_000 -> pluralize(div(seconds, 86_400), "day")
      seconds < 31_104_000 -> pluralize(div(seconds, 2_592_000), "month")
      true -> pluralize(div(seconds, 31_104_000), "year")
    end
  end

  def pluralize(1, thing), do: "1 #{thing}"
  def pluralize(n, thing), do: "#{n} #{Inflex.pluralize(thing)}"

  def sign_up_enabled?, do: Accounts.sign_up_enabled?()

  def admin_panel_enabled?, do: AsciinemaWeb.Plug.AdminGate.enabled?()

  def safe_json(value) do
    json =
      value
      |> Jason.encode!()
      |> String.replace(~r/</, "\\u003c")

    {:safe, json}
  end

  def render_markdown(input) do
    input = String.trim("#{input}")

    if present?(input) do
      {:safe, HtmlSanitizeEx.basic_html(Earmark.as_html!(input))}
    end
  end
end
