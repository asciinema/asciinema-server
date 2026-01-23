defmodule AsciinemaWeb.UserRecordingHTML do
  use AsciinemaWeb, :html
  import Scrivener.HTML
  alias AsciinemaWeb.RecordingHTML

  embed_templates "user_recording_html/*"

  defdelegate profile_link(user), to: AsciinemaWeb.UserHTML
  defdelegate username(user), to: AsciinemaWeb.UserHTML
end
