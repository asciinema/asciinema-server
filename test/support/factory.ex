defmodule Asciinema.Factory do
  use ExMachina.Ecto, repo: Asciinema.Repo
  alias Asciinema.Accounts.{Cli, User}
  alias Asciinema.FileStore
  alias Asciinema.Recordings.Asciicast
  alias Asciinema.Streaming.Stream

  def user_factory do
    %User{
      username: sequence(:username, &"username-#{&1}"),
      email: sequence(:email, &"email-#{&1}@example.com"),
      auth_token: Crypto.random_token(20),
      default_recording_visibility: :unlisted,
      default_stream_visibility: :unlisted
    }
  end

  def temporary_user_factory do
    %{user_factory() | email: nil}
  end

  def cli_factory do
    %Cli{
      user: build(:user),
      token: sequence(:token, &"token-#{&1}")
    }
  end

  def revoked_cli_factory do
    %Cli{
      user: build(:user),
      token: sequence(:token, &"token-#{&1}"),
      revoked_at: Timex.now()
    }
  end

  def asciicast_factory do
    build(:asciicast_v2)
  end

  def asciicast_v1_factory do
    %Asciicast{
      user: build(:user),
      version: 1,
      path: sequence(:path, &"recordings/#{&1}.json"),
      duration: 123.45,
      cols: 80,
      rows: 24,
      secret_token: sequence(:secret_token, &secret_token/1),
      snapshot: [[["foo", %{}]], [["bar", %{}]]]
    }
  end

  def asciicast_v2_factory do
    %Asciicast{
      user: build(:user),
      version: 2,
      path: sequence(:path, &"recordings/#{&1}.cast"),
      duration: 123.45,
      cols: 80,
      rows: 24,
      secret_token: sequence(:secret_token, &secret_token/1),
      snapshot: [[["foo", %{}]], [["bar", %{}]]]
    }
  end

  def stream_factory do
    %Stream{
      user: build(:user),
      public_token: sequence(:public_token, &public_token/1),
      producer_token: sequence(:producer_token, &"token-#{&1}")
    }
  end

  defp public_token(n) do
    "public-#{n}"
    |> String.codepoints()
    |> Elixir.Stream.cycle()
    |> Elixir.Stream.take(16)
    |> Enum.join("")
  end

  defp secret_token(n) do
    "sekrit-#{n}"
    |> String.codepoints()
    |> Elixir.Stream.cycle()
    |> Elixir.Stream.take(25)
    |> Enum.join("")
  end

  def with_file(asciicast) do
    src =
      case asciicast.version do
        1 -> "welcome.json"
        2 -> "welcome.cast"
      end

    :ok = FileStore.put_file(asciicast.path, "test/fixtures/#{src}", "application/json")

    asciicast
  end
end
