defmodule AsciinemaWeb.UserStreamHTML do
  use AsciinemaWeb, :html

  embed_templates "user_stream_html/*"

  defdelegate profile_link(user), to: AsciinemaWeb.UserHTML
  defdelegate username(user), to: AsciinemaWeb.UserHTML
end
