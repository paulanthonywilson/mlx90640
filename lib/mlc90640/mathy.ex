defmodule Mlc90640.Mathy do
  @moduledoc false
  _doc = """
  There's quite a bit of maths involved in interpreting the thermal
  image. Here's some maths functions.
  """

  @doc """
  The number of times start can be doubled while still being
  less than the maximum
  """
  @spec maximum_doubling_while_less_than(number(), number()) :: non_neg_integer()
  def maximum_doubling_while_less_than(start, maximum) do
    (maximum / start)
    |> :math.log2()
    |> ceil()
  end

  @doc """
  The maximum absolute value in the `Enum`
  """
  @spec abs_max(Enum.t()) :: number()
  def abs_max([]), do: nil

  def abs_max(numbers) do
    numbers
    |> Enum.map(&Kernel.abs/1)
    |> Enum.max()
  end

  @doc """
  Rounds float to the nearest integer, and truncates to an integer
  """
  def round_to_int(f) do
    f |> Float.round() |> trunc()
  end
end
