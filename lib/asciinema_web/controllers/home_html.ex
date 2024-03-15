defmodule AsciinemaWeb.HomeHTML do
  use AsciinemaWeb, :html
  import AsciinemaWeb.RecordingHTML, only: [player_src: 1, player_opts: 2]
  alias AsciinemaWeb.RecordingHTML

  embed_templates "home/*.html"
end
