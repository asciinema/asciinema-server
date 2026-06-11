defmodule AsciinemaAdmin.SavedQuery do
  @moduledoc "Shared admin saved query preset."
  use Ecto.Schema
  import Ecto.Changeset

  @entities ~w[users recordings streams]

  schema "admin_saved_queries" do
    field :entity, :string
    field :name, :string
    field :filter, :string
    field :normalized_filter, :string
    field :sort, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(saved_query, attrs) do
    saved_query
    |> cast(attrs, [:entity, :name, :filter, :normalized_filter, :sort])
    |> update_change(:entity, &String.downcase/1)
    |> update_change(:name, &String.trim/1)
    |> update_change(:filter, &String.trim/1)
    |> update_change(:normalized_filter, &String.trim/1)
    |> update_change(:sort, fn sort -> sort |> String.trim() |> String.downcase() end)
    |> validate_required([:entity, :name, :filter, :normalized_filter, :sort])
    |> validate_inclusion(:entity, @entities)
    |> validate_length(:name, max: 80)
    |> validate_length(:filter, max: 500)
    |> validate_length(:normalized_filter, max: 500)
    |> unique_constraint(:name, name: :admin_saved_queries_entity_name_index)
    |> unique_constraint(:normalized_filter,
      name: :admin_saved_queries_entity_filter_sort_index,
      message: "has already been saved with this sort"
    )
  end
end
