defmodule Asciinema.AccountsTest do
  import Asciinema.Fixtures
  use Asciinema.DataCase
  alias Asciinema.Accounts
  alias Asciinema.Accounts.User

  describe "verify_signup_token/1" do
    test "invalid token" do
      assert Accounts.verify_signup_token("invalid") == {:error, :token_invalid}
    end

    test "valid token" do
      token = Accounts.signup_token("test@example.com")
      assert {:ok, %User{}} = Accounts.verify_signup_token(token)
      assert Accounts.verify_signup_token(token) == {:error, :email_taken}
    end
  end
end
