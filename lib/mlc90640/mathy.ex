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
  def maximum_doubling_while_less_than(start, maximum) do
    (maximum / start)
    |> :math.log2()
    |> ceil()
  end
end
