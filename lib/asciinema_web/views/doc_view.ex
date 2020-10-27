defmodule AsciinemaWeb.DocView do
  use AsciinemaWeb, :view

  @titles %{
    :"how-it-works" => "How it works",
    :"getting-started" => "Getting started",
    :installation => "Installation",
    :usage => "Usage",
    :config => "Configuration file",
    :embedding => "Sharing & embedding",
    :faq => "FAQ"
  }

  def title_for(topic) do
    @titles[topic]
  end

  def topic_link(conn, current_topic, topic) do
    class = if current_topic == topic, do: "active"
    render("topic_link.html", conn: conn, topic: topic, text: title_for(topic), class: class)
  end
end
