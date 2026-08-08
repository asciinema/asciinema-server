defmodule Asciinema.Streaming.ProducerSession do
  # Pure per-connection protocol state for a stream producer. Side effects
  # are returned as data for the socket to execute:
  #
  #   {:persist_protocol, name}    - save the negotiated/detected protocol
  #   {:reset_stream, args}        - ensure/claim the stream server and reset it
  #   {:stream_event, type, args}  - forward an event to the stream server
  #   :stop_stream                 - stop the stream server
  #
  # The session returned by receive_frame/3 is pending: the caller commits it
  # only after the effects succeed, so a failure cannot leave it online.

  alias Asciinema.Streaming.Parser

  defstruct phase: :new, parser: nil, stop_on_close: nil, bucket: nil

  @max_cols 720
  @max_rows 200

  def new(protocol, bucket_opts) do
    session = %__MODULE__{bucket: new_bucket(bucket_opts)}

    if protocol do
      {session, effects} = select_parser(session, Parser.new(protocol))

      {session, effects}
    else
      {session, []}
    end
  end

  @doc """
  Runs one incoming frame through parser selection, parsing, and command
  validation. Returns effects in execution order and the pending session,
  or an error with the effects already determined before the failure
  (protocol persistence happens even when the first frame fails to parse).
  """
  def receive_frame(session, frame, now_us)

  def receive_frame(%__MODULE__{parser: nil} = session, {opcode, payload} = frame, now_us) do
    {session, effects} = select_parser(session, Parser.new(Parser.detect({opcode, payload})))

    case do_receive_frame(session, frame, now_us) do
      {:ok, more_effects, session} -> {:ok, effects ++ more_effects, session}
      {:error, reason, more_effects} -> {:error, reason, effects ++ more_effects}
    end
  end

  def receive_frame(%__MODULE__{} = session, frame, now_us) do
    do_receive_frame(session, frame, now_us)
  end

  def drain_bucket(%__MODULE__{bucket: bucket} = session, byte_count) do
    tokens = bucket.tokens - byte_count

    if tokens < 0 do
      {:error, :bucket_empty}
    else
      {:ok, put_in(session.bucket.tokens, tokens)}
    end
  end

  def refill_bucket(%__MODULE__{bucket: bucket} = session) do
    put_in(session.bucket.tokens, min(bucket.size, bucket.tokens + bucket.fill_amount))
  end

  def parser_selected?(%__MODULE__{parser: parser}), do: parser != nil

  def parser_name(%__MODULE__{parser: parser}), do: Parser.name(parser)

  def online?(%__MODULE__{phase: phase}), do: phase == :online

  def stop_on_close?(%__MODULE__{stop_on_close: stop}), do: stop

  # Internals

  defp new_bucket(opts) do
    %{
      size: opts[:size],
      tokens: opts[:size],
      fill_amount: opts[:fill_amount]
    }
  end

  defp select_parser(session, parser) do
    # protocols with EOT (alis) stop the stream server via the :eot command;
    # the rest stop it on producer disconnect
    stop = not Parser.supports?(parser, :eot)

    session = %{session | parser: parser, stop_on_close: stop}

    {session, [{:persist_protocol, Parser.name(parser)}]}
  end

  defp do_receive_frame(session, frame, now_us) do
    with {:ok, commands, parser} <- run_parser(session.parser, frame, now_us),
         {:ok, effects, session} <- apply_commands(commands, %{session | parser: parser}) do
      {:ok, effects, session}
    else
      {:error, reason} -> {:error, reason, []}
    end
  end

  defp run_parser(parser, frame, now_us) do
    with {:error, reason} <- Parser.parse(parser, frame, now_us) do
      {:error, {:parser, reason, frame}}
    end
  end

  defp apply_commands(commands, session) do
    Enum.reduce_while(commands, {:ok, [], session}, fn command, {:ok, effects, session} ->
      case apply_command(command, session) do
        {:ok, new_effects, session} -> {:cont, {:ok, effects ++ new_effects, session}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp apply_command({:init, %{term_size: {cols, rows}} = args}, %{phase: phase} = session)
       when phase != :online do
    if cols > 0 and rows > 0 and cols <= @max_cols and rows <= @max_rows do
      {:ok, [{:reset_stream, args}], %{session | phase: :online}}
    else
      {:error, {:invalid_vt_size, {cols, rows}}}
    end
  end

  defp apply_command({:output, args}, %{phase: :online} = session) do
    {:ok, [{:stream_event, :output, args}], session}
  end

  defp apply_command({:input, args}, %{phase: :online} = session) do
    {:ok, [{:stream_event, :input, args}], session}
  end

  defp apply_command({:resize, %{term_size: {cols, rows}} = args}, session)
       when cols > 0 and rows > 0 and cols <= @max_cols and rows <= @max_rows do
    {:ok, [{:stream_event, :resize, args}], session}
  end

  defp apply_command({:resize, %{term_size: size}}, _session) do
    {:error, {:invalid_vt_size, size}}
  end

  defp apply_command({:marker, args}, %{phase: :online} = session) do
    {:ok, [{:stream_event, :marker, args}], session}
  end

  defp apply_command({:exit, args}, %{phase: :online} = session) do
    {:ok, [{:stream_event, :exit, args}], %{session | stop_on_close: true}}
  end

  defp apply_command({:eot, _args}, %{phase: :online} = session) do
    {:ok, [:stop_stream], %{session | phase: :eot, stop_on_close: false}}
  end

  # a valid command in the wrong phase closes instead of crashing the socket
  defp apply_command({command, _args}, session) do
    {:error, {:invalid_command, command, session.phase}}
  end
end
