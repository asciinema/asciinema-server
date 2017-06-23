defmodule Asciinema.ExpiringToken do
  use Asciinema.Web, :model

  schema "expiring_tokens" do
    belongs_to :user, Asciinema.User
  end
end
