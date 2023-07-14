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

  @doc """
  Chunk the EEprom into areas of interest for easier parsing
  """
  @spec new(binary) :: t()
  def new(eeprom) do
    %__MODULE__{
      registers: binary_part(eeprom, 0, 0x20),
      occ: binary_part(eeprom, 0x20, 0x20),
      acc: binary_part(eeprom, 0x40, 0x20),
      gain_etc: binary_part(eeprom, 0x60, 0x20),
      pixel_offsets: binary_part(eeprom, 0x80, 0x600)
    }
  end
end
