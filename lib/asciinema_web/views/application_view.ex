defmodule AsciinemaWeb.ApplicationView do
  import Phoenix.HTML.Tag, only: [content_tag: 3]
  alias Asciinema.Accounts

  def present?([]), do: false
  def present?(nil), do: false
  def present?(""), do: false
  def present?(_), do: true

  def time_tag(time) do
    iso_8601_ts = Timex.format!(time, "{ISO:Extended:Z}")
    rfc_1123_ts = Timex.format!(time, "{RFC1123z}")

    content_tag(:time, datetime: iso_8601_ts) do
      "on #{rfc_1123_ts}"
    end
  end

  def time_ago_tag(time) do
    iso_8601_ts = Timex.format!(time, "{ISO:Extended:Z}")
    rfc_1123_ts = Timex.format!(time, "{RFC1123z}")

    content_tag(:time, datetime: iso_8601_ts, title: rfc_1123_ts) do
      Timex.from_now(time)
    end
  end

  def pluralize(1, thing), do: "1 #{thing}"
  def pluralize(n, thing), do: "#{n} #{Inflex.pluralize(thing)}"

  def sign_up_enabled?, do: Accounts.sign_up_enabled?()

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
