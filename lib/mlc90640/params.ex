defmodule Mlc90640.Params do
  @moduledoc false
  _doc = """
  Holds the data extracted from the EEProm
  """

  defmodule KsTo do
    @moduledoc false
    defstruct ks_to_0: nil,
              ks_to_1: nil,
              ks_to_2: nil,
              ks_to_3: nil,
              ks_to_4: -0.0002,
              ct_0: -40,
              ct_1: 0,
              ct_2: nil,
              ct_3: nil,
              ct_4: 400,
              step: nil,
              ks_to_scale: nil

    @type t :: %__MODULE__{
            ks_to_0: float(),
            ks_to_1: float(),
            ks_to_2: float(),
            ks_to_3: float(),
            ks_to_4: float(),
            ct_0: integer(),
            ct_1: integer(),
            ct_2: integer(),
            ct_3: integer(),
            ct_4: integer(),
            step: integer(),
            ks_to_scale: integer()
          }
  end

  defmodule Cp do
    @moduledoc false
    defstruct [:kv, :kta, :alpha_0, :alpha_1, :offset_0, :offset_1]

    @type t :: %__MODULE__{
            kv: float(),
            kta: float(),
            alpha_0: float(),
            alpha_1: float(),
            offset_0: integer(),
            offset_1: integer()
          }
  end

  defstruct [
    :kv_vdd,
    :vdd_25,
    :kv_ptat,
    :kt_ptat,
    :v_ptat25,
    :alpha_ptat,
    :gain,
    :tgc,
    :ksta,
    :ks_to,
    :cp,
    :alpha_scale,
    :alphas,
    :offsets,
    :kta_scale,
    :ktas
  ]

  @type t :: %__MODULE__{
          kv_vdd: integer(),
          vdd_25: integer(),
          kv_ptat: float(),
          kt_ptat: float(),
          v_ptat25: integer(),
          alpha_ptat: float(),
          gain: integer(),
          tgc: float(),
          ksta: float(),
          ks_to: KsTo.t(),
          cp: Cp.t(),
          alpha_scale: pos_integer(),
          alphas: list(pos_integer()),
          offsets: list(integer()),
          kta_scale: non_neg_integer(),
          ktas: list(integer())
        }
end
