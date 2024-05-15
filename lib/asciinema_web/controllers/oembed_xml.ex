defmodule AsciinemaWeb.OembedXML do
  use Phoenix.Component
  alias AsciinemaWeb.OembedJSON

  embed_templates "oembed/*.xml"

  def show(assigns) do
    ~H"""
    <.rich {OembedJSON.show(assigns)} />
    """
  end
end
