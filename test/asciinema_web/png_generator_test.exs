defmodule AsciinemaWeb.PngGeneratorTest do
  use ExUnit.Case, async: true

  alias AsciinemaWeb.PngGenerator.Error

  test "retryable flag can be set on retryable failures" do
    assert %Error{retryable: true} = %Error{type: :busy, reason: 30_000, retryable: true}

    assert %Error{retryable: true} = %Error{
             type: :timeout,
             reason: :rsvg_convert,
             retryable: true
           }
  end

  test "retryable defaults to false" do
    assert %Error{retryable: false} = %Error{type: :generator_failed, reason: {"oops", 1}}
  end
end
