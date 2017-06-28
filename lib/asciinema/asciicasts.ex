defmodule Asciinema.Asciicasts do
  import Ecto.Query, warn: false
  alias Asciinema.{Repo, Asciicast, FileStore}
  alias Asciinema.Asciicasts.PosterGenerator

  def get_asciicast!(id) when is_integer(id) do
    Repo.get!(Asciicast, id)
  end
  def get_asciicast!(thing) when is_binary(thing) do
    q = if String.length(thing) == 25 do
      from a in Asciicast, where: a.secret_token == ^thing
    else
      case Integer.parse(thing) do
        {id, ""} ->
          from a in Asciicast, where: a.private == false and a.id == ^id
        _ ->
          from a in Asciicast, where: a.id == -1 # TODO fixme
      end
    end

    Repo.one!(q)
  end

  def create_asciicast(user, params, user_agent \\ nil)

  def create_asciicast(user, %Plug.Upload{path: path, filename: filename} = upload, user_agent) do
    asciicast = %Asciicast{user_id: user.id,
                           user_agent: user_agent,
                           file: filename,
                           private: user.asciicasts_private_by_default}

    files = [{:file, upload}]

    with {:ok, json} <- File.read(path),
         {:ok, attrs} <- Poison.decode(json),
         {:ok, attrs} <- extract_attrs(attrs),
         changeset = Asciicast.create_changeset(asciicast, attrs),
         {:ok, %Asciicast{} = asciicast} <- do_create_asciicast(changeset, files) do
      generate_poster(asciicast)
      {:ok, asciicast}
    else
      {:error, :invalid} ->
        {:error, :parse_error}
      otherwise ->
        otherwise
    end
  end

  def create_asciicast(user, %{"meta" => attrs,
                               "stdout" => %Plug.Upload{} = data,
                               "stdout_timing" => %Plug.Upload{} = timing}, user_agent) do
    asciicast = %Asciicast{user_id: user.id,
                           user_agent: unless(attrs["uname"], do: user_agent),
                           stdout_data: data.filename,
                           stdout_timing: timing.filename,
                           private: user.asciicasts_private_by_default}

    attrs = Map.put(attrs, "version", 0)
    changeset = Asciicast.create_changeset(asciicast, attrs)
    files = [{:stdout_data, data}, {:stdout_timing, timing}]

    case do_create_asciicast(changeset, files) do
      {:ok, %Asciicast{} = asciicast} ->
        generate_poster(asciicast)
        {:ok, asciicast}
      otherwise ->
        otherwise
    end
  end

  defp extract_attrs(%{"version" => 1} = attrs) do
    attrs = %{version: attrs["version"],
              duration: attrs["duration"],
              terminal_columns: attrs["width"],
              terminal_lines: attrs["height"],
              terminal_type: get_in(attrs, ["env", "TERM"]),
              command: attrs["command"],
              shell: get_in(attrs, ["env", "SHELL"]),
              title: attrs["title"]}
    {:ok, attrs}
  end
  defp extract_attrs(_attrs) do
    {:error, :unknown_format}
  end

  defp do_create_asciicast(changeset, files) do
    {_, result} = Repo.transaction(fn ->
      case Repo.insert(changeset) do
        {:ok, %Asciicast{} = asciicast} ->
          Enum.each(files, fn {type, upload} -> save_file(asciicast, type, upload) end)
          {:ok, asciicast}
        otherwise ->
          otherwise
      end
    end)

    result
  end

  defp save_file(asciicast, type, %{path: tmp_file_path, content_type: content_type}) do
    file_store_path = Asciicast.file_store_path(asciicast, type)
    :ok = FileStore.put_file(file_store_path, tmp_file_path, content_type)
  end

  defp generate_poster(asciicast) do
    PosterGenerator.generate(asciicast)
  end

  def stdout_stream(stdout_timing_path, stdout_data_path) do
    Stream.resource(
      fn -> open_stream_files(stdout_timing_path, stdout_data_path) end,
      fn {timing_file, data_file} = files ->
        case IO.read(timing_file, :line) do
          line when is_binary(line) ->
            {delay, count} = parse_line(line)
            case IO.read(data_file, count) do
              text when is_binary(text) ->
                {[{delay, text}], files}
              otherwise ->
                {:error, otherwise}
            end
          _ ->
            {:halt, files}
        end
      end,
      fn {timing_file, data_file} ->
        File.close(timing_file)
        File.close(data_file)
      end
    )
  end

  defp open_stream_files(stdout_timing_path, stdout_data_path) do
    {open_stream_file(stdout_timing_path),
     open_stream_file(stdout_data_path)}
  end

  defp open_stream_file(path) do
    header = File.open!(path, [:read], fn file -> IO.binread(file, 2) end)

    case header do
      <<0x1f,0x8b>> -> # gzip
        File.open!(path, [:read, :compressed])
      <<0x42,0x5a>> -> # bzip
        {:ok, tmp_path} = Briefly.create()
        {_, 0} = System.cmd("sh", ["-c", "bzip2 -d -k -c #{path} >#{tmp_path}"])
        File.open!(tmp_path, [:read])
      _ ->
        File.open!(path, [:read])
    end
  end

  defp parse_line(line) do
    [delay_s, bytes_s] = line |> String.trim_trailing |> String.split(" ")
    {String.to_float(delay_s), String.to_integer(bytes_s)}
  end
end
