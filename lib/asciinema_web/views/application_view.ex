defmodule AsciinemaWeb.ApplicationView do
  import Phoenix.HTML.Tag, only: [content_tag: 3]

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
end
