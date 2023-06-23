defmodule Asciinema.Fixtures do
  alias Asciinema.{Repo, Recordings}
  alias Asciinema.Accounts
  alias Asciinema.Accounts.User

  def fixture(what, attrs \\ %{})

  def fixture(:upload, attrs) do
    fixture(:upload_v1, attrs)
  end

  def fixture(:upload_v1, attrs) do
    path = Map.get(attrs, :path) || "1/asciicast.json"
    filename = Path.basename(path)

    %Plug.Upload{
      path: "test/fixtures/#{path}",
      filename: filename,
      content_type: "application/json"
    }
  end

  def fixture(:upload_v2, attrs) do
    path = Map.get(attrs, :path) || "2/full.cast"
    filename = Path.basename(path)

    %Plug.Upload{
      path: "test/fixtures/#{path}",
      filename: filename,
      content_type: "application/octet-stream"
    }
  end

  def fixture(:user, attrs) do
    attrs =
      Map.merge(
        %{username: "test", email: "test@example.com"},
        attrs
      )

    %User{}
    |> Accounts.change_user(attrs)
    |> Repo.insert!()
  end

  def fixture(:asciicast, attrs) do
    fixture(:asciicast_v2, attrs)
  end

  def fixture(:asciicast_v1, _attrs) do
    user = fixture(:user)
    upload = fixture(:upload_v1)
    {:ok, asciicast} = Recordings.create_asciicast(user, upload)
    asciicast
  end

  def fixture(:asciicast_v2, _attrs) do
    user = fixture(:user)
    upload = fixture(:upload_v2)
    {:ok, asciicast} = Recordings.create_asciicast(user, upload)
    asciicast
  end
end
