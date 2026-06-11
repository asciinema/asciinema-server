defmodule AsciinemaAdmin.Icons do
  @moduledoc "Admin SVG icons, embedded from `icons/*.html.heex`."
  use Phoenix.Component

  embed_templates "icons/*"
end
