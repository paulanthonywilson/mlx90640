defmodule Mlc90640.Params do
  @moduledoc false
  _doc = """
  Holds the data extracted from the EEProm
  """

  defstruct [:kv_vdd, :vdd_25, :kv_ptat, :kt_ptat, :v_ptat25, :alpha_ptat, :gain]

  @type t :: %__MODULE__{
          kv_vdd: integer(),
          vdd_25: integer(),
          kv_ptat: float(),
          kt_ptat: float(),
          v_ptat25: integer(),
          alpha_ptat: float(),
          gain: integer()
        }
end
