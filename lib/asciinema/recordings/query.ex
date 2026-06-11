defmodule Asciinema.Recordings.Query do
  @moduledoc """
  Typed query spec for recording listings.

  This is a domain-level input to `Asciinema.Recordings` query builders. It
  intentionally uses concepts such as `:user`, `:stream`, and `:full_text`
  instead of exposing backing column names to callers.
  """

  @enforce_keys [:scope]
  defstruct scope: nil,
            archived: :exclude,
            filters: [],
            sort: nil
end
