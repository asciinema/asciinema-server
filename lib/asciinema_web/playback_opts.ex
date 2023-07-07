defmodule AsciinemaWeb.PlayerOpts do
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
            |> Enum.zip(Stream.iterate(1, &(&1 * 60)))
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
    field :startAt, Time
    field :idleTimeLimit, :float
    field :theme, :string
  end

  def parse(attrs, :recording) do
    parse(attrs, __MODULE__.__schema__(:fields))
  end

  def parse(attrs, :live_stream) do
    parse(attrs, [:autoplay, :cols, :poster, :rows, :theme])
  end

  def parse(attrs, fields) when is_list(fields) do
    changeset =
      %__MODULE__{}
      |> cast(attrs, fields)
      |> validate_number(:speed, greater_than: 0.0)
      |> validate_number(:startAt, greater_than: 0)
      |> validate_number(:idleTimeLimit, greater_than_or_equal_to: 0.5)
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
    t = Keyword.get(opts, :startAt)

    if autoplay == nil && t != nil do
      Keyword.put(opts, :autoplay, true)
    else
      opts
    end
  end

  def set_poster(opts) do
    autoplay = Keyword.get(opts, :autoplay)
    t = Keyword.get(opts, :startAt)
    poster = Keyword.get(opts, :poster)

    if poster == nil && t != nil && t > 0 && !autoplay do
      Keyword.put(opts, :poster, "npt:#{t}")
    else
      opts
    end
  end
end
