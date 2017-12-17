defmodule AsciinemaWeb.ApplicationView do
  import Phoenix.HTML.Tag, only: [content_tag: 3]

  def present?([]), do: false
  def present?(nil), do: false
  def present?(_), do: true

  def time_ago_tag(time) do
    iso_8601_ts = Timex.format!(time, "{ISO:Extended:Z}")
    rfc_1123_ts = Timex.format!(time, "{RFC1123z}")

    content_tag(:time, class: "timeago", datetime: iso_8601_ts) do
      "on #{rfc_1123_ts}"
    end
  end
end
