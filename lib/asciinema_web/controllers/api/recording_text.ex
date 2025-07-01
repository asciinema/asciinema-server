defmodule AsciinemaWeb.Api.RecordingTEXT do
  use Phoenix.Component
  alias AsciinemaWeb.Api.RecordingJSON

  def created(assigns) do
    RecordingJSON.created(assigns).message
  end
end
