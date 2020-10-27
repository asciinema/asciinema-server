defmodule Asciinema.Factory do
  use ExMachina.Ecto, repo: Asciinema.Repo
  alias Asciinema.Accounts.User
  alias Asciinema.Asciicasts.Asciicast
  alias Asciinema.FileStore

  def user_factory do
    %User{
      username: sequence(:username, &"username-#{&1}"),
      email: sequence(:email, &"email-#{&1}@example.com"),
      auth_token: Crypto.random_token(20)
    }
  end

  def asciicast_factory do
    build(:asciicast_v2)
  end

  def asciicast_v0_factory do
    %Asciicast{
      user: build(:user),
      version: 0,
      path: nil,
      stdout_data: "stdout",
      stdout_timing: "stdout.time",
      duration: 123.45,
      terminal_columns: 80,
      terminal_lines: 24,
      secret_token: sequence(:secret_token, &"sekrit-#{&1}"),
      snapshot: [[["foo", %{}]], [["bar", %{}]]]
    }
  end

  def asciicast_v1_factory do
    %Asciicast{
      user: build(:user),
      version: 1,
      path: sequence(:path, &"asciicasts/01/01/#{&1}.json"),
      duration: 123.45,
      terminal_columns: 80,
      terminal_lines: 24,
      secret_token: sequence(:secret_token, &"sekrit-#{&1}"),
      snapshot: [[["foo", %{}]], [["bar", %{}]]]
    }
  end

  def asciicast_v2_factory do
    %Asciicast{
      user: build(:user),
      version: 2,
      path: sequence(:path, &"asciicasts/01/01/#{&1}.cast"),
      duration: 123.45,
      terminal_columns: 80,
      terminal_lines: 24,
      secret_token: sequence(:secret_token, &"sekrit-#{&1}"),
      snapshot: [[["foo", %{}]], [["bar", %{}]]]
    }
  end

  def with_file(asciicast) do
    src =
      case asciicast.version do
        1 -> "welcome.json"
        2 -> "welcome.cast"
      end

    :ok = FileStore.put_file(asciicast.path, "test/fixtures/#{src}", "application/json", false)

    asciicast
  end

  def with_files(%{version: 0} = asciicast) do
    src = "test/fixtures/0.9.9/stdout"
    ct = "application/octet-stream"
    :ok = FileStore.put_file("asciicast/stdout/#{asciicast.id}/stdout", src, ct, false)

    src = "test/fixtures/0.9.9/stdout.time"
    ct = "application/octet-stream"

    :ok =
      FileStore.put_file("asciicast/stdout_timing/#{asciicast.id}/stdout.time", src, ct, false)

    asciicast
  end

  def with_files(asciicast) do
    with_file(asciicast)
  end
end
