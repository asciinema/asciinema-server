defmodule Asciinema.FileStore.LocalTest do
  use ExUnit.Case, async: false
  alias Asciinema.FileStore.Local

  setup :set_local_path

  defp set_local_path(%{tmp_dir: tmp_dir}) do
    store_root = Path.join(tmp_dir, "store")
    previous = Application.get_env(:asciinema, Local)
    Application.put_env(:asciinema, Local, path: store_root)

    on_exit(fn ->
      case previous do
        nil -> Application.delete_env(:asciinema, Local)
        _ -> Application.put_env(:asciinema, Local, previous)
      end
    end)

    {:ok, store_root: store_root}
  end

  describe "put_file/3" do
    @tag :tmp_dir
    test "copies a file into the local store", %{tmp_dir: tmp_dir, store_root: store_root} do
      src_path = Path.join(tmp_dir, "source.txt")
      File.write!(src_path, "hello")

      assert :ok = Local.put_file("dst/hello.txt", src_path, "text/plain")
      assert File.read!(Path.join(store_root, "dst/hello.txt")) == "hello"
    end
  end

  describe "move_file/2" do
    @tag :tmp_dir
    test "moves a file inside the local store", %{store_root: store_root} do
      src_path = Path.join(store_root, "src.txt")
      File.mkdir_p!(Path.dirname(src_path))
      File.write!(src_path, "hello")

      assert :ok = Local.move_file("src.txt", "dst/moved.txt")
      refute File.exists?(src_path)
      assert File.read!(Path.join(store_root, "dst/moved.txt")) == "hello"
    end
  end

  describe "open_file/1" do
    @tag :tmp_dir
    test "opens a file for reading", %{store_root: store_root} do
      path = Path.join(store_root, "file.txt")
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "hello")

      assert {:ok, io} = Local.open_file("file.txt")
      assert IO.read(io, :eof) == "hello"
      File.close(io)

      assert {:ok, "hello"} = Local.open_file("file.txt", fn io -> IO.read(io, :eof) end)
    end
  end

  describe "delete_file/1" do
    @tag :tmp_dir
    test "removes a file from the local store", %{store_root: store_root} do
      path = Path.join(store_root, "file.txt")
      File.mkdir_p!(Path.dirname(path))
      File.write!(path, "hello")

      assert :ok = Local.delete_file("file.txt")
      refute File.exists?(path)
    end
  end
end
