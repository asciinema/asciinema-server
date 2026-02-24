defmodule Asciinema.FileCacheTest do
  use ExUnit.Case, async: true

  alias Asciinema.FileCache

  describe "get_path/5" do
    test "cache miss then cache hit runs generator only once" do
      %{pid: cache} = start_cache(buckets: [txt: 60], cache_cleanup_interval: 10)
      counter = start_counter()
      generator = generator(counter, "hello")

      path1 = FileCache.get_path(cache, :txt, :key1, generator)
      path2 = FileCache.get_path(cache, :txt, :key1, generator)

      assert path1 == path2
      assert counter_value(counter) == 1
    end

    test "concurrent requests for same key are coalesced" do
      %{pid: cache} = start_cache(buckets: [txt: 60], cache_cleanup_interval: 10)
      counter = start_counter()
      generator = generator(counter, "hello", sleep_ms: 50)

      results =
        1..8
        |> Task.async_stream(
          fn _ -> FileCache.get_path(cache, :txt, {:same, 1}, generator) end,
          max_concurrency: 8,
          timeout: 5_000,
          ordered: false
        )
        |> Enum.map(fn {:ok, path} -> path end)

      assert length(Enum.uniq(results)) == 1
      assert counter_value(counter) == 1
    end

    test "custom timeout can be passed for slow generator" do
      %{pid: cache} = start_cache(buckets: [txt: 60], cache_cleanup_interval: 10)
      counter = start_counter()
      generator = generator(counter, "hello", sleep_ms: 100)

      path = FileCache.get_path(cache, :txt, :slow_key, generator, 1_000)

      assert File.read!(path) == "hello"
      assert counter_value(counter) == 1
    end

    test "raises on generator failure" do
      %{pid: cache} = start_cache(buckets: [txt: 60], cache_cleanup_interval: 10)

      error =
        assert_raise FileCache.Error, fn ->
          FileCache.get_path(cache, :txt, :boom, fn _ ->
            raise "boom"
          end)
        end

      assert error.type == :generator_failed
      assert error.bucket == :txt
      assert error.key == :boom
    end
  end

  describe "fetch_path/5" do
    test "returns error on generator failure and cache process survives" do
      %{pid: cache} = start_cache(buckets: [txt: 60], cache_cleanup_interval: 10)

      assert {:error,
              %FileCache.Error{
                type: :generator_failed,
                bucket: :txt,
                key: :boom,
                kind: :error,
                reason: %RuntimeError{message: "boom"},
                stacktrace: _stacktrace
              }} =
               FileCache.fetch_path(cache, :txt, :boom, fn _ ->
                 raise "boom"
               end)

      assert Process.alive?(cache)

      counter = start_counter()
      path = FileCache.get_path(cache, :txt, :boom, generator(counter, "ok"))

      assert File.read!(path) == "ok"
      assert counter_value(counter) == 1
    end

    test "returns timeout error when generator takes too long" do
      %{pid: cache} = start_cache(buckets: [txt: 60], cache_cleanup_interval: 10)
      counter = start_counter()
      generator = generator(counter, "hello", sleep_ms: 100)

      assert {:error,
              %FileCache.Error{
                type: :timeout,
                bucket: :txt,
                key: :slow_key,
                reason: 10
              }} = FileCache.fetch_path(cache, :txt, :slow_key, generator, 10)

      assert Process.alive?(cache)

      Process.sleep(150)

      path = FileCache.get_path(cache, :txt, :slow_key, generator)
      assert File.read!(path) == "hello"
      assert counter_value(counter) == 1
    end

    test "returns invalid_generator_output when generator returns invalid path" do
      %{pid: cache} = start_cache(buckets: [txt: 60], cache_cleanup_interval: 10)

      assert {:error,
              %FileCache.Error{
                type: :invalid_generator_output,
                bucket: :txt,
                key: :bad_output,
                reason: {:invalid_return, :ok}
              }} = FileCache.fetch_path(cache, :txt, :bad_output, fn _tmp_dir -> :ok end)
    end
  end

  describe "collect/prune cycle" do
    test "removes stale files and keeps fresh files" do
      %{pid: cache, path: base_path, buckets: buckets} =
        start_cache(buckets: [txt: 60, svg: 60], cache_cleanup_interval: 10)

      txt_counter = start_counter()
      svg_counter = start_counter()
      txt_generator = generator(txt_counter, "txt", mtime: 1)
      svg_generator = generator(svg_counter, "svg")

      FileCache.get_path(cache, :txt, :txt_key, txt_generator)
      FileCache.get_path(cache, :svg, :svg_key, svg_generator)

      assert counter_value(txt_counter) == 1
      assert counter_value(svg_counter) == 1

      base_path
      |> FileCache.collect_stale_files(buckets)
      |> FileCache.prune_stale_files()

      FileCache.get_path(cache, :txt, :txt_key, txt_generator)
      FileCache.get_path(cache, :svg, :svg_key, svg_generator)

      assert counter_value(txt_counter) == 2
      assert counter_value(svg_counter) == 1
    end

    test "scheduler runs collect on configured interval" do
      %{pid: cache} = start_cache(buckets: [txt: 60], cache_cleanup_interval: 1)
      counter = start_counter()
      generator = generator(counter, "hello", mtime: 1)

      FileCache.get_path(cache, :txt, :interval_key, generator)
      assert counter_value(counter) == 1

      Process.sleep(1_500)

      FileCache.get_path(cache, :txt, :interval_key, generator)
      assert counter_value(counter) == 2
    end
  end

  describe "start_link/1" do
    test "path is required" do
      assert_raise KeyError, fn ->
        FileCache.start_link([])
      end
    end
  end

  defp start_cache(opts) do
    path = unique_cache_path()
    buckets = Keyword.get(opts, :buckets, [])
    pid = start_supervised!({FileCache, [path: path] ++ opts})

    %{pid: pid, path: path, buckets: buckets}
  end

  defp start_counter do
    :atomics.new(1, [])
  end

  defp counter_value(counter) do
    :atomics.get(counter, 1)
  end

  defp generator(counter, content, opts \\ []) do
    sleep_ms = Keyword.get(opts, :sleep_ms, 0)
    mtime = Keyword.get(opts, :mtime)

    fn tmp_dir ->
      _ = :atomics.add_get(counter, 1, 1)

      if sleep_ms > 0 do
        Process.sleep(sleep_ms)
      end

      tmp_path = Path.join(tmp_dir, "value.txt")

      :ok = File.write(tmp_path, content)

      if mtime do
        :ok = File.touch(tmp_path, mtime)
      end

      tmp_path
    end
  end

  defp unique_cache_path do
    Briefly.create!(directory: true)
  end
end
