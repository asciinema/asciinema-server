defmodule Asciinema.Accounts.Query do
  @moduledoc """
  Typed query spec for user listings.
  """

  @enforce_keys [:scope]
  defstruct scope: nil,
            filters: [],
            sort: nil
end
