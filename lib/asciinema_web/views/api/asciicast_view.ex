defmodule AsciinemaWeb.Api.AsciicastView do
  use AsciinemaWeb, :view

  def render("created.text", %{url: url}) do
    url
  end

  def render("created.json", %{url: url}) do
    %{url: url}
  end

  def render("error.json", %{changeset: changeset}) do
    %{errors: translate_errors(changeset)}
  end

  def translate_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, &translate_error/1)
  end
end
