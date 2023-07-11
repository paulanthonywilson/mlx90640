defmodule Mlc90640.Bytey do
  @moduledoc false
  _doc = """
  Some helper functions for byte oriented operations
  """

  import Bitwise

  @doc """
  Converts an int to an unsigned two bytes. Errors rather than overflows.
  """
  @spec to_unsigned_2_bytes(non_neg_integer()) :: <<_::16>>
  def to_unsigned_2_bytes(i) when i >= 0 and i <= 0xFFFF do
    <<i >>> 8, i &&& 0xFF>>
  end

  def bin_to_values(bin) do
    for <<i::size(16) <- bin>>, do: i
  end

  @spec two_complement(non_neg_integer(), pos_integer()) :: integer()
  def two_complement(value, bit_count \\ 16) when value >= 0 do
    neg_subtract = 2 ** bit_count

    max = Integer.floor_div(neg_subtract, 2) - 1

    if value > max do
      raise_for_overflow(value - neg_subtract, bit_count)
    else
      value
    end
  end

  defp raise_for_overflow(should_be_negative, bit_count) do
    unless should_be_negative < 0 do
      raise("2's complement overflow: #{should_be_negative} does not fit in #{bit_count} bits")
    end

    should_be_negative
  end
end
