defmodule Asciinema.Fixtures do
  alias Asciinema.{Repo, Asciicast, User}

  def fixture(:upload) do
    %Plug.Upload{path: "resources/welcome.json",
                 filename: "welcome.json",
                 content_type: "application/json"}
  end

  def fixture(:user) do
    attrs = %{username: "test",
              auth_token: "authy-auth-auth"}
    Repo.insert!(User.changeset(%User{}, attrs))
  end

  def fixture(:asciicast) do
    user = fixture(:user)
    upload = fixture(:upload)
    attrs = %{version: 1,
              duration: 123,
              terminal_columns: 80,
              terminal_lines: 24,
              file: upload.filename,
              secret_token: "v3ry-sekr1t",
              user_id: user.id}
    Repo.insert!(Asciicast.changeset(%Asciicast{}, attrs))
  end
end
