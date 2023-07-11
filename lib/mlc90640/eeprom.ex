defmodule Mlc90640.Eeprom do
  @moduledoc false
  _doc = """
  Struct holding Eeprom split into areas for ease of access
  """

  keys = [:registers, :occ, :acc, :gain_etc, :pixel_offsets]
  @enforce_keys keys
  defstruct keys

  @type t :: %__MODULE__{
          registers: binary(),
          occ: binary(),
          acc: binary(),
          gain_etc: binary(),
          pixel_offsets: binary()
        }
end
