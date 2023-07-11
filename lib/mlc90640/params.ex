defmodule Mlc90640.Params do
  @moduledoc false
  _doc = """
  Holds the data extracted from the EEProm
  """

  defstruct [:kv_vdd, :vdd_25, :kv_ptat, :kt_ptat, :v_ptat25, :alpha_ptat]

  @type t :: %__MODULE__{
          kv_vdd: integer(),
          vdd_25: integer()
        }
end
