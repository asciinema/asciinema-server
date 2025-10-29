defmodule AsciinemaWeb.SearchHTML do
  use AsciinemaWeb, :html
  import Scrivener.HTML
  alias AsciinemaWeb.RecordingHTML

  embed_templates "search_html/*"
end
