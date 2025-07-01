defmodule AsciinemaWeb.Api.RecordingTEXT do
  alias AsciinemaWeb.Api.RecordingJSON

  def created(assigns) do
    RecordingJSON.created(assigns).message
  end
end
