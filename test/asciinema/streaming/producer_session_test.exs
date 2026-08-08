defmodule Asciinema.Streaming.ProducerSessionTest do
  use ExUnit.Case, async: true

  alias Asciinema.Streaming.Alis
  alias Asciinema.Streaming.ProducerSession

  @bucket_opts [size: 100, fill_amount: 10]
  @magic "ALiS\x01"

  test "new with a negotiated protocol selects the parser and persists the protocol" do
    {session, effects} = ProducerSession.new("v1.alis", @bucket_opts)

    assert effects == [{:persist_protocol, "v1.alis"}]
    assert ProducerSession.parser_selected?(session)
    refute ProducerSession.online?(session)
    # alis supports EOT, so the server is not stopped on disconnect
    assert ProducerSession.stop_on_close?(session) == false
  end

  test "new without a protocol selects nothing" do
    {session, effects} = ProducerSession.new(nil, @bucket_opts)

    assert effects == []
    refute ProducerSession.parser_selected?(session)
  end

  test "the first frame auto-detects, persists, and parses in one go" do
    {session, []} = ProducerSession.new(nil, @bucket_opts)

    assert {:ok, effects, session} =
             ProducerSession.receive_frame(session, {:binary, "raw output"}, 42)

    assert [{:persist_protocol, "raw"}, {:reset_stream, %{term_size: {80, 24}}}] = effects
    assert ProducerSession.online?(session)
    # raw has no EOT, so the server is stopped on disconnect
    assert ProducerSession.stop_on_close?(session) == true
  end

  test "the ALIS lifecycle produces effects in order with absolute times" do
    {session, _effects} = ProducerSession.new("v1.alis", @bucket_opts)

    assert {:ok, [], session} = ProducerSession.receive_frame(session, {:binary, @magic}, 0)

    init = Alis.V1.encode_frame({:init, %{last_id: 0, time: 500, term_size: {80, 24}}})

    assert {:ok, [{:reset_stream, %{time: 500}}], session} =
             ProducerSession.receive_frame(session, {:binary, init}, 0)

    assert ProducerSession.online?(session)

    output = Alis.V1.encode_frame({:output, %{id: 1, rel_time: 100, text: "hi"}})

    assert {:ok, [{:stream_event, :output, %{id: 1, time: 600, text: "hi"}}], session} =
             ProducerSession.receive_frame(session, {:binary, output}, 0)

    exit_frame = Alis.V1.encode_frame({:exit, %{id: 2, rel_time: 1, status: 0}})

    assert {:ok, [{:stream_event, :exit, _}], session} =
             ProducerSession.receive_frame(session, {:binary, exit_frame}, 0)

    assert ProducerSession.stop_on_close?(session) == true

    # legacy id + time EOT, as the CLI emits it
    assert {:ok, [:stop_stream], session} =
             ProducerSession.receive_frame(session, {:binary, <<4, 3, 50>>}, 0)

    refute ProducerSession.online?(session)
    assert ProducerSession.stop_on_close?(session) == false
  end

  test "invalid init dimensions error without effects" do
    {session, _effects} = ProducerSession.new("v1.alis", @bucket_opts)
    {:ok, [], session} = ProducerSession.receive_frame(session, {:binary, @magic}, 0)

    init = Alis.V1.encode_frame({:init, %{last_id: 0, time: 0, term_size: {0, 24}}})

    assert {:error, {:invalid_vt_size, {0, 24}}, []} =
             ProducerSession.receive_frame(session, {:binary, init}, 0)

    oversized = Alis.V1.encode_frame({:init, %{last_id: 0, time: 0, term_size: {721, 24}}})

    assert {:error, {:invalid_vt_size, {721, 24}}, []} =
             ProducerSession.receive_frame(session, {:binary, oversized}, 0)
  end

  test "a valid command in the wrong phase errors instead of raising" do
    {session, _effects} = ProducerSession.new("v1.alis", @bucket_opts)
    {:ok, [], session} = ProducerSession.receive_frame(session, {:binary, @magic}, 0)

    # legacy EOT is accepted by the parser in its :init phase, but the
    # session is still in :new
    assert {:error, {:invalid_command, :eot, :new}, []} =
             ProducerSession.receive_frame(session, {:binary, <<4, 1, 0>>}, 0)
  end

  test "parser errors are wrapped with the offending frame" do
    {session, _effects} = ProducerSession.new("v1.alis", @bucket_opts)

    assert {:error, {:parser, :message_invalid, {:binary, "bogus"}}, []} =
             ProducerSession.receive_frame(session, {:binary, "bogus"}, 0)
  end

  test "drain_bucket errors on the exact boundary and refill_bucket caps at size" do
    {session, _effects} = ProducerSession.new("v1.alis", @bucket_opts)

    assert {:ok, session} = ProducerSession.drain_bucket(session, 100)
    assert session.bucket.tokens == 0
    assert {:error, :bucket_empty} = ProducerSession.drain_bucket(session, 1)

    session = ProducerSession.refill_bucket(session)
    assert session.bucket.tokens == 10

    session = %{session | bucket: %{session.bucket | tokens: 95}}
    assert ProducerSession.refill_bucket(session).bucket.tokens == 100
  end
end
