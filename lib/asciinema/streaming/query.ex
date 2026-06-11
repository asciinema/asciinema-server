defmodule Asciinema.Streaming.Query do
  @moduledoc """
  Typed query spec for stream listings.
  """

  @enforce_keys [:scope]
  defstruct scope: nil,
            filters: [],
            sort: nil
end
