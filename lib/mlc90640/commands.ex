defmodule Mlc90640.Commands do
  @moduledoc false
  _doc = """
  Things for setting up the control registry. We only want to change the frames per second and
  ensure that the reading is "Chess board"
  """

  import Bitwise

  @chess_board 1 <<< 12
  @existing_control_bits_mask 0b1110110001111111

  def control_reg1_with_fps(fps) when is_float(fps) do
    case {Float.round(fps, 1), Float.round(fps)} do
      {0.5, _} ->
        do_control_reg1_with_fps(0.5)

      {whole, whole} ->
        whole |> trunc() |> control_reg1_with_fps()

      _ ->
        unsupported_fps(fps)
    end
  end

  def control_reg1_with_fps(fps) do
    unless fps in [1, 2, 4, 6, 8, 16, 32, 64], do: unsupported_fps(fps)
    do_control_reg1_with_fps(fps)
  end

  def control_reg1_with_fps(current_value, fps) do
    bor(
      current_value &&& @existing_control_bits_mask,
      control_reg1_with_fps(fps)
    )
  end

  defp do_control_reg1_with_fps(fps) do
    fps_pattern = trunc(:math.log2(fps) + 1) <<< 7

    bor(@chess_board, fps_pattern)
  end

  defp unsupported_fps(fps) do
    raise "Only fps of 0.5, 1, 2, 4, 6, 8, 16, 32, or 64 allowed not #{fps}"
  end
end
