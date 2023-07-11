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
end
