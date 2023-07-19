defmodule Mlc90640.Eeprom.Params do
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
    :ktas,
    :kv_scale,
    :kvs,
    :calibration_mode_ee,
    :il_chess_c,
    :broken_pixels,
    :outlier_pixels,
    :resolution_ee
  ]

  @type t :: %__MODULE__{
          kv_vdd: nil | integer(),
          vdd_25: nil | integer(),
          kv_ptat: nil | float(),
          kt_ptat: nil | float(),
          v_ptat25: nil | integer(),
          alpha_ptat: nil | float(),
          gain: nil | integer(),
          tgc: nil | float(),
          ksta: nil | float(),
          ks_to: nil | KsTo.t(),
          cp: nil | Cp.t(),
          alpha_scale: nil | pos_integer(),
          alphas: nil | list(pos_integer()),
          offsets: nil | list(integer()),
          kta_scale: nil | non_neg_integer(),
          ktas: nil | list(integer()),
          kv_scale: nil | non_neg_integer(),
          kvs: nil | list(integer()),
          calibration_mode_ee: nil | non_neg_integer(),
          il_chess_c: nil | {float(), float(), float()},
          broken_pixels: nil | list(pixel_index :: non_neg_integer()),
          outlier_pixels: nil | list(pixel_index :: non_neg_integer()),
          resolution_ee: nil | non_neg_integer()
        }
end
