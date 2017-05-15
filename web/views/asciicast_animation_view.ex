defmodule Asciinema.AsciicastAnimationView do
  use Asciinema.Web, :view

  def asciicast_file_url(conn, asciicast) do
    "#{asciicast_url(conn, :show, asciicast)}.json" # TODO: use route helper
  end
end
