defmodule Mlc90640.ByteyTest do
  use ExUnit.Case
  alias Mlc90640.Bytey

  describe "to_unsigned_2_bytes" do
    test "is correct" do
      assert <<0, 0>> == Bytey.to_unsigned_2_bytes(0)
      assert <<0, 1>> == Bytey.to_unsigned_2_bytes(1)
      assert <<0, 255>> == Bytey.to_unsigned_2_bytes(255)
      assert <<1, 0>> == Bytey.to_unsigned_2_bytes(256)
      assert <<255, 255>> == Bytey.to_unsigned_2_bytes(65_535)
    end

    test "is constrained" do
      assert_raise FunctionClauseError, fn -> Bytey.to_unsigned_2_bytes(-1) end
      assert_raise FunctionClauseError, fn -> Bytey.to_unsigned_2_bytes(65_536) end
    end
  end
end
