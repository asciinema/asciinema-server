defmodule Asciinema.Fixtures do
  alias Asciinema.{Repo, Asciicasts, User}

  def fixture(what, attrs \\ %{})

  def fixture(:upload, attrs) do
    path = Map.get(attrs, :path) || "1/asciicast.json"
    filename = Path.basename(path)
    %Plug.Upload{path: "spec/fixtures/#{path}",
                 filename: filename,
                 content_type: "application/json"}
  end

  def fixture(:user, _attrs) do
    attrs = %{username: "test",
              auth_token: "authy-auth-auth"}
    Repo.insert!(User.changeset(%User{}, attrs))
  end

  def fixture(:asciicast, _attrs) do
    user = fixture(:user)
    upload = fixture(:upload)
    {:ok, asciicast} = Asciicasts.create_asciicast(user, upload)
    asciicast
  end
end
