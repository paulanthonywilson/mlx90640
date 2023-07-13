defmodule Mlc90640.EepromParamsExtraction do
  @moduledoc false
  _doc = """
  Extracts parameters from the eeprom that has been read
  """

  import Bitwise

  alias Mlc90640.{Bytey, Eeprom, Params}

  @two_pow_13 2 ** 13

  @spec vdd(Params.t(), Eeprom.t()) :: Params.t()
  def vdd(params, %Eeprom{gain_etc: gain_etc}) do
    <<_::48, kv_vdd::8, vdd_25::8>> <> _ = gain_etc

    %{
      params
      | kv_vdd: Bytey.two_complement(kv_vdd, 8) <<< 5,
        vdd_25: ((vdd_25 - 256) <<< 5) - @two_pow_13
    }
  end

  @spec ptat(Params.t(), Eeprom.t()) :: Params.t()
  def ptat(params, %Eeprom{gain_etc: gain_etc, occ: occ}) do
    <<_::16, v_ptat25::16, kv_ptat::6, kt_ptat::10>> <> _ = gain_etc

    kv_ptat = Bytey.two_complement(kv_ptat, 6) / 4096
    kt_ptat = Bytey.two_complement(kt_ptat, 10) / 8

    v_ptat25 = Bytey.two_complement(v_ptat25)

    <<alpha_ptat::4, _::4>> <> _ = occ
    alpha_ptat = alpha_ptat / 4 + 8
    %{params | kv_ptat: kv_ptat, kt_ptat: kt_ptat, v_ptat25: v_ptat25, alpha_ptat: alpha_ptat}
  end

  @spec gain(Params.t(), Eeprom.t()) :: Params.t()
  def gain(params, %Eeprom{gain_etc: gain_etc}) do
    <<gain::16>> <> _ = gain_etc
    %{params | gain: Bytey.two_complement(gain)}
  end

  @spec tgc(Params.t(), Eeprom.t()) :: Params.t()
  def tgc(params, %Eeprom{gain_etc: gain_etc}) do
    <<_::200, tgc>> <> _ = gain_etc
    tgc = Bytey.two_complement(tgc, 8) / 32
    %{params | tgc: tgc}
  end

  @spec ksta(Params.t(), Eeprom.t()) :: Params.t()
  def ksta(params, %Eeprom{gain_etc: gain_etc}) do
    <<_::192, ksta>> <> _ = gain_etc
    ksta = Bytey.two_complement(ksta, 8) / 8192
    %{params | ksta: ksta}
  end

  @spec ksto(Params.t(), Eeprom.t()) :: Params.t()
  def ksto(params, %Eeprom{gain_etc: gain_etc}) do
    <<_::208, ks_to_1, ks_to_0, ks_to_3, ks_to_2, _::2, step::2, ct_3::4, ct_2::4,
      ks_to_scale::4>> = gain_etc

    ks_to_scale = ks_to_scale + 8
    ks_divisor = 1 <<< ks_to_scale
    step = step * 10
    ct_2 = ct_2 * step
    ct_3 = ct_2 + ct_3 * step

    ks_to_0 = Bytey.two_complement(ks_to_0, 8) / ks_divisor
    ks_to_1 = Bytey.two_complement(ks_to_1, 8) / ks_divisor
    ks_to_2 = Bytey.two_complement(ks_to_2, 8) / ks_divisor
    ks_to_3 = Bytey.two_complement(ks_to_3, 8) / ks_divisor

    ks_to = %Params.KsTo{
      ks_to_scale: ks_to_scale,
      step: step,
      ct_2: ct_2,
      ct_3: ct_3,
      ks_to_0: ks_to_0,
      ks_to_1: ks_to_1,
      ks_to_2: ks_to_2,
      ks_to_3: ks_to_3
    }

    %{params | ks_to: ks_to}
  end

  def read_alpha_scale(%{acc: <<alpha_scale::4, _::4>> <> _}) do
    alpha_scale + 27
  end
end
