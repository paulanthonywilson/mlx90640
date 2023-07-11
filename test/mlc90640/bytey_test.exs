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

  describe "to  values" do
    test "defaults converting binary to a 16 bit list" do
      assert [] = Bytey.bin_to_values(<<>>)
      assert [1] = Bytey.bin_to_values(<<0, 1>>)
      assert [255] = Bytey.bin_to_values(<<0, 255>>)
      assert [256] = Bytey.bin_to_values(<<1, 0>>)
      assert [256, 255] = Bytey.bin_to_values(<<1, 0, 0, 255>>)
    end
  end

  describe "two complement" do
    test "with 16 bit" do
      assert 0 == Bytey.two_complement(0)
      assert 1 == Bytey.two_complement(1)
      assert 32_767 == Bytey.two_complement(32_767)
      assert -1 == Bytey.two_complement(65_535)
      assert -32_768 == Bytey.two_complement(32_768)
    end

    test "with 4 bit" do
      assert 0 == Bytey.two_complement(0, 4)
      assert 1 == Bytey.two_complement(1, 4)
      assert 7 == Bytey.two_complement(7, 4)
      assert -8 == Bytey.two_complement(8, 4)
      assert -1 == Bytey.two_complement(15, 4)
    end

    test "errors on overflow" do
      assert_raise RuntimeError, fn -> Bytey.two_complement(256, 8) end
      assert_raise FunctionClauseError, fn -> Bytey.two_complement(-1, 8) end
    end
  end
end
