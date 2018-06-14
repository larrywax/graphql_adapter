defmodule GrapqlAdapterTest do
  use ExUnit.Case
  doctest GrapqlAdapter

  test "greets the world" do
    assert GrapqlAdapter.call("localhost:80", "query()", %{}) == {:error, :econnrefused}
  end
end
