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
end
