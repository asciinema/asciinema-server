defmodule AsciinemaWeb.CliHTML do
  use AsciinemaWeb, :html

  embed_templates "cli_html/*"

  def install_id_preview(install_id) do
    if String.length(install_id) <= 16 do
      install_id
    else
      "#{String.slice(install_id, 0, 8)}...#{String.slice(install_id, -8, 8)}"
    end
  end

  def recording_count_text(1), do: "1 recording"
  def recording_count_text(count), do: "#{count} recordings"
end
