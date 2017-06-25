defmodule Asciinema.Repo do
  use Ecto.Repo, otp_app: :asciinema

  def count(query) do
    aggregate(query, :count, :id)
  end
end
