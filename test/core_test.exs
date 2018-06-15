defmodule GraphqlAdapterTest do
  use ExUnit.Case
  doctest GraphqlAdapter.Core

  test "greets the world" do
    assert GraphqlAdapter.Core.call("localhost:80", "query()", %{}) == {:error, :econnrefused}
  end
end
