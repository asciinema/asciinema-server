defmodule Asciinema.FileStore.S3Test do
  use ExUnit.Case, async: true
  alias Asciinema.AppEnv
  alias Asciinema.FileStore.S3

  setup do
    AppEnv.put(S3, bucket: "test-bucket", path: "uploads/")

    :ok
  end

  defp capture_requests(response \\ {:ok, %{}}) do
    test_pid = self()

    AppEnv.put(:s3_request_fn, fn operation ->
      send(test_pid, {:s3_request, operation})
      response
    end)
  end

  describe "uri/1" do
    test "returns a presigned URL for the path under the base path" do
      url = S3.uri("casts/1.cast")

      assert url =~ "test-bucket"
      assert url =~ "uploads/casts/1.cast"
      assert url =~ "X-Amz-Signature="
    end
  end

  describe "put_file/3" do
    @tag :tmp_dir
    test "uploads the file body with content type under the base path", %{tmp_dir: tmp_dir} do
      capture_requests()
      src_path = Path.join(tmp_dir, "src.cast")
      File.write!(src_path, "{}")

      assert S3.put_file("casts/1.cast", src_path, "application/x-asciicast") == :ok

      assert_received {:s3_request, operation}

      assert operation ==
               ExAws.S3.put_object("test-bucket", "uploads/casts/1.cast", "{}",
                 content_type: "application/x-asciicast"
               )
    end

    @tag :tmp_dir
    test "returns the error from S3", %{tmp_dir: tmp_dir} do
      capture_requests({:error, {:http_error, 500, %{}}})
      src_path = Path.join(tmp_dir, "src.cast")
      File.write!(src_path, "{}")

      assert S3.put_file("casts/1.cast", src_path, "application/x-asciicast") ==
               {:error, {:http_error, 500, %{}}}
    end
  end

  describe "move_file/2" do
    test "copies to the new path, then deletes the old file" do
      capture_requests()

      assert S3.move_file("a.cast", "b/c.cast") == :ok

      assert_received {:s3_request, copy_operation}
      assert_received {:s3_request, delete_operation}

      assert copy_operation ==
               ExAws.S3.put_object_copy(
                 "test-bucket",
                 "uploads/b/c.cast",
                 "test-bucket",
                 "uploads/a.cast"
               )

      assert delete_operation == ExAws.S3.delete_object("test-bucket", "uploads/a.cast")
    end

    test "returns enoent and skips the delete when the source is missing" do
      capture_requests({:error, {:http_error, 404, %{}}})

      assert S3.move_file("a.cast", "b/c.cast") == {:error, :enoent}

      assert_received {:s3_request, _copy_operation}
      refute_received {:s3_request, _}
    end

    test "returns the error and skips the delete when the copy fails" do
      capture_requests({:error, {:http_error, 500, %{}}})

      assert S3.move_file("a.cast", "b/c.cast") == {:error, {:http_error, 500, %{}}}

      assert_received {:s3_request, _copy_operation}
      refute_received {:s3_request, _}
    end
  end

  describe "delete_file/1" do
    test "deletes the file under the base path" do
      capture_requests()

      assert S3.delete_file("a.cast") == :ok

      assert_received {:s3_request, operation}
      assert operation == ExAws.S3.delete_object("test-bucket", "uploads/a.cast")
    end
  end
end
