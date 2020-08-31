defmodule Asciinema.Asciicasts.PlaybackOpts do
  use Ecto.Schema
  import Ecto.Changeset

  defmodule Boolean do
    use Ecto.Type

    def type, do: :boolean

    def cast(value) when value in [0, "0", "false"], do: {:ok, false}
    def cast(value) when value in [1, "1", "true"], do: {:ok, true}
    def cast(other), do: Ecto.Type.cast(:boolean, other)

    def load(data), do: Ecto.Type.load(:boolean, data)

    def dump(value), do: Ecto.Type.dump(:boolean, value)
  end

  defmodule Time do
    use Ecto.Type

    def type, do: :integer

    def cast(value) when is_binary(value) do
      parts =
        value
        |> String.trim()
        |> String.split(":", parts: 3)
        |> Enum.reduce([], fn s, acc ->
          case Integer.parse(s) do
            {f, _} -> [f | acc]
            _ -> []
          end
        end)

      case parts do
        [] ->
          :error

        _ ->
          t =
            parts
            |> Enum.zip(Stream.iterate(1, & &1 * 60))
            |> Enum.map(fn {a, b} -> a * b end)
            |> Enum.sum()

          {:ok, t}
      end
    end

    def cast(other), do: Ecto.Type.cast(:integer, other)

    def load(data), do: Ecto.Type.load(:integer, data)

    def dump(value), do: Ecto.Type.dump(:integer, value)
  end

  @primary_key false
  schema "" do
    field :autoplay, Boolean
    field :cols, :integer
    field :loop, Boolean
    field :poster, :string
    field :preload, Boolean
    field :rows, :integer
    field :size, :string
    field :speed, :float
    field :t, Time
    field :theme, :string
  end

  def parse(attrs) do
    changeset =
      %__MODULE__{}
      |> cast(attrs, __MODULE__.__schema__(:fields))
      |> validate_number(:speed, greater_than: 0.0)
      |> validate_number(:t, greater_than: 0)
      |> validate_number(:cols, greater_than: 0)
      |> validate_number(:rows, greater_than: 0)

    error_fields = for {k, _v} <- changeset.errors, do: k
    changeset = Enum.reduce(error_fields, changeset, &delete_change(&2, &1))

    changeset
    |> apply_changes()
    |> Map.from_struct()
    |> Map.take(Map.keys(changeset.changes))
    |> Map.to_list()
    |> set_autoplay()
    |> set_poster()
  end

  defp set_autoplay(opts) do
    autoplay = Keyword.get(opts, :autoplay)
    t = Keyword.get(opts, :t)

    if autoplay == nil && t != nil do
      Keyword.put(opts, :autoplay, true)
    else
      opts
    end
  end

  def set_poster(opts) do
    autoplay = Keyword.get(opts, :autoplay)
    t = Keyword.get(opts, :t)
    poster = Keyword.get(opts, :poster)

    if poster == nil && t != nil && t > 0 && !autoplay do
      Keyword.put(opts, :poster, "npt:#{t}")
    else
      opts
    end
  end
end
