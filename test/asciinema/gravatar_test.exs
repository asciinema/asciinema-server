defmodule Asciinema.GravatarTest do
  use ExUnit.Case, async: true
  alias Asciinema.Gravatar

  test "default options" do
    assert Gravatar.gravatar_url("test@example.com") ==
             "//gravatar.com/avatar/55502f40dc8b7c769880b10874abc9d0?s=128&d=retro"
  end

  test "custom options" do
    assert Gravatar.gravatar_url("test@example.com", size: 256, default: "mm") ==
             "//gravatar.com/avatar/55502f40dc8b7c769880b10874abc9d0?s=256&d=mm"
  end
end
