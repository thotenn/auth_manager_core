defmodule AuthManagerTest do
  use ExUnit.Case
  doctest AuthManager

  test "greets the world" do
    assert AuthManager.hello() == :world
  end
end
