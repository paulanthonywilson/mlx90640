defmodule Mlc90640.PixelsTest do
  use ExUnit.Case
  alias Mlc90640.Pixels

  describe "row and column to pixel index" do
    test "is correct" do
      assert Pixels.pixel_index(0, 0) == 0
      assert Pixels.pixel_index(0, 31) == 31
      assert Pixels.pixel_index(23, 31) == 767
    end

    test "is constrained" do
      assert_raise FunctionClauseError, fn -> Pixels.pixel_index(-1, 0) end
      assert_raise FunctionClauseError, fn -> Pixels.pixel_index(0, -1) end
      assert_raise FunctionClauseError, fn -> Pixels.pixel_index(0, 32) end
      assert_raise FunctionClauseError, fn -> Pixels.pixel_index(24, 0) end
    end
  end

  describe "pixel index to row and column" do
    test "is correct" do
      assert Pixels.row_and_column(0) == {0, 0}
      assert Pixels.row_and_column(31) == {0, 31}
      assert Pixels.row_and_column(767) == {23, 31}
    end

    test "is constrained" do
      assert_raise FunctionClauseError, fn -> Pixels.row_and_column(-1) end
      assert_raise FunctionClauseError, fn -> Pixels.row_and_column(768) end
    end
  end
end
