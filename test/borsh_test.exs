defmodule Estuary.BorshTest do
  use ExUnit.Case, async: true

  alias Estuary.Anchor.Borsh

  setup do
    {:ok, %{}}
  end

  test "decode u8" do
    assert Borsh.decode(<<5>>, "u8", %{}) == {:ok, 5, <<>>}
    assert Borsh.decode(<<-1>>, "u8", %{}) == {:ok, 255, <<>>}
  end
end
