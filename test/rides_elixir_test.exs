defmodule RidesElixirTest do
  use ExUnit.Case
  doctest RidesElixir

  test "start the app" do
    assert RidesElixir.run() == :ok
  end
end
