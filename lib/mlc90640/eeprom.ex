defmodule Mlc90640.Eeprom do
  @moduledoc false
  _doc = """
  Struct holding Eeprom split into areas for ease of access
  """

  defstruct registers: <<0::256>>,
            occ: <<0::256>>,
            acc: <<0::256>>,
            gain_etc: <<0::256>>,
            pixel_offsets: <<0::1536>>

  @type t :: %__MODULE__{
          registers: binary(),
          occ: binary(),
          acc: binary(),
          gain_etc: binary(),
          pixel_offsets: binary()
        }
end
