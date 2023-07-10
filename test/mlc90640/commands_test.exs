defmodule Mlc90640.CommandsTest do
  use ExUnit.Case
  alias Mlc90640.Commands

  import Bitwise

  @reading_pattern_mask 0b0001000000000000
  @fps_mask 0b0000001110000000

  describe "control_reg_fps" do
    test "always sets chessboard" do
      assert 0x1000 == (Commands.control_reg1_with_fps(2) &&& @reading_pattern_mask)
      assert 0x1000 == (Commands.control_reg1_with_fps(4) &&& @reading_pattern_mask)
      assert 0x1000 == (Commands.control_reg1_with_fps(8) &&& @reading_pattern_mask)
    end

    test "sets fps" do
      assert 0 == (Commands.control_reg1_with_fps(0.5) &&& @fps_mask)
      assert 0 == (Commands.control_reg1_with_fps(0.49999999) &&& @fps_mask)
      assert 0b0010000000 == (Commands.control_reg1_with_fps(1) &&& @fps_mask)
      assert 0b0010000000 == (Commands.control_reg1_with_fps(1.0) &&& @fps_mask)
      assert 0b0010000000 == (Commands.control_reg1_with_fps(1.04) &&& @fps_mask)
      assert 0b0100000000 == (Commands.control_reg1_with_fps(2) &&& @fps_mask)
      assert 0b0110000000 == (Commands.control_reg1_with_fps(4) &&& @fps_mask)
      assert 0b1000000000 == (Commands.control_reg1_with_fps(8) &&& @fps_mask)
      assert 0b1010000000 == (Commands.control_reg1_with_fps(16) &&& @fps_mask)
      assert 0b1100000000 == (Commands.control_reg1_with_fps(32) &&& @fps_mask)
      assert 0b1110000000 == (Commands.control_reg1_with_fps(64) &&& @fps_mask)
    end

    test "only supported fps values are set" do
      assert_raise(RuntimeError, fn -> Commands.control_reg1_with_fps(0.4) end)
      assert_raise(RuntimeError, fn -> Commands.control_reg1_with_fps(5.5) end)
      assert_raise(RuntimeError, fn -> Commands.control_reg1_with_fps(1.1) end)

      assert_raise(RuntimeError, fn ->
        Commands.control_reg1_with_fps(3) |> Integer.to_string(2)
      end)
    end

    test "does not change other bits" do
      assert 0b1111110001111111 == Commands.control_reg1_with_fps(0xFFFF, 0.5)
      assert 0b0001000000000000 == Commands.control_reg1_with_fps(0x00, 0.5)
      assert 0b0001001110000000 == Commands.control_reg1_with_fps(0x00, 64)
    end
  end
end
