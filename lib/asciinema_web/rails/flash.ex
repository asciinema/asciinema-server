defmodule AsciinemaWeb.Rails.Flash do
  import Plug.Conn

  def put_rails_flash(conn, key, value) do
    key = case key do
            :info -> :notice
            :error -> :alert
            key -> key
          end

    put_session(conn, :flash, %{discard: [], flashes: %{key => value}})
  end
end
