defmodule Asciinema.Workers.CreateStreamRecording do
  use Oban.Worker, queue: :default

  alias Asciinema.{Accounts, FileStore, HttpUtil, Recordings}
  require Logger

  @download_timeout 60_000
  @stream_filename "stream.cast"

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    %{
      "user_id" => user_id,
      "stream_id" => stream_id,
      "file_store_path" => file_store_path
    } = args

    base_attrs = %{
      user_agent: args["user_agent"],
      term_bold_is_bright: args["term_bold_is_bright"],
      term_adaptive_palette: args["term_adaptive_palette"],
      term_cursor_mode: args["term_cursor_mode"],
      keystroke_overlay: args["keystroke_overlay"]
    }

    case Accounts.fetch_user(user_id) do
      {:ok, user} ->
        finalize(user, stream_id, file_store_path, base_attrs)

      {:error, :not_found} ->
        Logger.warning(
          "CreateStreamRecording: user #{user_id} not found, discarding staged capture #{file_store_path}"
        )

        :discard
    end
  end

  defp finalize(user, stream_id, file_store_path, base_attrs) do
    with {:ok, local_path} <- fetch(file_store_path) do
      case create(user, stream_id, local_path, base_attrs) do
        {:ok, _asciicast} ->
          _ = FileStore.delete_file(file_store_path)
          :ok

        {:error, :empty_recording} ->
          Logger.info(
            "CreateStreamRecording: stream #{inspect(stream_id)} produced an empty recording, discarding staged capture #{file_store_path}"
          )

          _ = FileStore.delete_file(file_store_path)
          :discard

        {:error, reason} = err ->
          Logger.error(
            "CreateStreamRecording failed for stream #{inspect(stream_id)}: #{inspect(reason)}"
          )

          err
      end
    end
  end

  defp create(user, stream_id, local_path, base_attrs) do
    params = %{"filename" => @stream_filename}
    attrs = Map.put(base_attrs, :stream_id, stream_id)

    case Recordings.create_asciicast(user, local_path, attrs, params) do
      {:ok, asciicast} ->
        {:ok, asciicast}

      {:error, %Ecto.Changeset{} = changeset} ->
        if stream_id_fk_error?(changeset) do
          Logger.info(
            "CreateStreamRecording: stream #{stream_id} missing, retrying with stream_id: nil"
          )

          attrs = Map.put(base_attrs, :stream_id, nil)
          Recordings.create_asciicast(user, local_path, attrs, params)
        else
          {:error, changeset}
        end

      {:error, _} = err ->
        err
    end
  end

  defp stream_id_fk_error?(%Ecto.Changeset{errors: errors}) do
    Enum.any?(errors, fn
      {:stream_id, {_, opts}} -> Keyword.get(opts, :constraint) == :foreign
      _ -> false
    end)
  end

  defp fetch(file_store_path) do
    case FileStore.uri(file_store_path) do
      "file://" <> path ->
        {:ok, path}

      "http" <> _ = url ->
        # Briefly owns cleanup of this local working copy. The FileStore object
        # itself is deleted explicitly only after the recording is created.
        tmp_path = Briefly.create!()

        case HttpUtil.download_to(url, tmp_path, timeout: @download_timeout, decompress: false) do
          :ok -> {:ok, tmp_path}
          {:error, _reason} = err -> err
        end
    end
  end
end
