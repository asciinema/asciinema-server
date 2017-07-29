defmodule AsciinemaWeb.DocController do
  use AsciinemaWeb, :controller
  alias AsciinemaWeb.{DocView, ErrorView}

  @topics ["how-it-works", "getting-started", "installation", "usage", "config", "embedding", "faq"]

  def index(conn, _params) do
    redirect conn, to: doc_path(conn, :show, :"getting-started")
  end

  def show(conn, %{"topic" => topic}) when topic in @topics do
    topic = String.to_atom(topic)

    conn
    |> assign(:topic, topic)
    |> assign(:page_title, DocView.title_for(topic))
    |> put_layout(:docs)
    |> render("#{topic}.html")
  end

  def show(conn, _params) do
    conn
    |> put_status(404)
    |> render(ErrorView, "404.html")
  end

end
