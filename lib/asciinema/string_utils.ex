defmodule Asciinema.StringUtils do
  def valid_part(invalid_str, str) do
    case String.chunk(invalid_str <> str, :valid) do
      [] ->
        {"", ""}

      chunks ->
        str =
          chunks
          |> Enum.take(Enum.count(chunks) - 1)
          |> Enum.filter(&String.valid?/1)
          |> Enum.join()

        last = Enum.at(chunks, -1)

        if String.valid?(last) do
          {str <> last, ""}
        else
          {str, last}
        end
    end
  end
end
