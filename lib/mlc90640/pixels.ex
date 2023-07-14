defmodule Mlc90640.Pixels do
  @moduledoc false
  _doc = """
  To do with converting from pixel indexes to rows and columns
  """

  @row_count 24
  @column_count 32
  @pixel_count @row_count * @column_count

  def row_count, do: @row_count
  def column_count, do: @column_count
  def pixel_count, do: @pixel_count

  @spec pixel_index(pos_integer(), pos_integer()) :: pos_integer()
  def pixel_index(x, y) when x >= 0 and x < @row_count and y >= 0 and y < @column_count do
    32 * x + y
  end

  def row_and_column(index) when index >= 0 and index < @pixel_count do
    {Integer.floor_div(index, @column_count), rem(index, @column_count)}
  end
end
