defmodule AsciinemaAdmin.EnsureAdminTest do
  use Asciinema.DataCase, async: true

  import Asciinema.Factory

  alias AsciinemaAdmin.EnsureAdmin

  defp socket(endpoint), do: %Phoenix.LiveView.Socket{endpoint: endpoint}

  describe "on_mount/4 via the main (public) endpoint" do
    test "allows an admin" do
      admin = insert(:user, is_admin: true)

      assert {:cont, _} =
               EnsureAdmin.on_mount(
                 :default,
                 %{},
                 %{"user_id" => admin.id},
                 socket(AsciinemaWeb.Endpoint)
               )
    end

    test "halts a non-admin" do
      user = insert(:user)

      assert {:halt, _} =
               EnsureAdmin.on_mount(
                 :default,
                 %{},
                 %{"user_id" => user.id},
                 socket(AsciinemaWeb.Endpoint)
               )
    end

    test "halts an anonymous session" do
      assert {:halt, _} =
               EnsureAdmin.on_mount(:default, %{}, %{}, socket(AsciinemaWeb.Endpoint))
    end
  end

  test "allows mounts on the dedicated admin endpoint without a session" do
    assert {:cont, _} =
             EnsureAdmin.on_mount(:default, %{}, %{}, socket(AsciinemaAdmin.Endpoint))
  end
end
