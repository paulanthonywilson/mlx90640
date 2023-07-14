defmodule Mlc90640.EepromParamsExtraction do
  @moduledoc false
  _doc = """
  Extracts parameters from the eeprom that has been read
  """

  import Bitwise

  alias Mlc90640.{Bytey, Eeprom, Params, Pixels}

  @two_pow_13 2 ** 13

  @scale_alpha 0.000001

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

  @spec cp(Params.t(), Eeprom.t()) :: Params.t()
  def cp(params, %{gain_etc: gain_etc} = eeprom) do
    <<_::128, _::4, kv_scale::4, kta_scale_1::4, _::4, alpha_1::6, alpha_0::10, offset_1::6,
      offset_0::10, kv, kta>> <> _ = gain_etc

    offset_0 = Bytey.two_complement(offset_0, 10)

    offset_1 = Bytey.two_complement(offset_1, 6) + offset_0

    kv = Bytey.two_complement(kv, 8) / 2 ** kv_scale

    alpha_0 = Bytey.two_complement(alpha_0, 10) / 2 ** (27 + read_alpha_scale(eeprom))
    alpha_1 = (1 + Bytey.two_complement(alpha_1, 6) / 128) * alpha_0
    kta = Bytey.two_complement(kta, 8) / 2 ** (kta_scale_1 + 8)

    %{
      params
      | cp: %Params.Cp{
          offset_0: offset_0,
          offset_1: offset_1,
          alpha_0: alpha_0,
          alpha_1: alpha_1,
          kv: kv,
          kta: kta
        }
    }
  end

  @spec alpha(Params.t(), Eeprom.t()) :: Params.t()
  def alpha(params, %{acc: acc, pixel_offsets: pixel_offsets}) do
    <<working_alpha_scale::4, acc_row_scale::4, acc_col_scale::4, acc_remnand_scale::4,
      alpha_ref::16>> <>
      acc_row_cols_bin = acc

    working_alpha_scale = working_alpha_scale + 30
    alpha_ref = Bytey.two_complement(alpha_ref)

    {acc_row, acc_col} =
      acc_row_cols_bin
      |> Bytey.bin_to_values(4)
      |> Enum.map(&Bytey.two_complement(&1, 4))
      |> Enum.chunk_every(4)
      |> Enum.map(&Enum.reverse/1)
      |> List.flatten()
      |> Enum.split(Pixels.row_count())

    acc_row =
      acc_row
      |> Enum.map(&(&1 <<< acc_row_scale))
      |> :array.from_list()

    acc_col =
      acc_col
      |> Enum.map(&(&1 <<< acc_col_scale))
      |> :array.from_list()

    alpha_temp =
      for(<<_::6, alpha_temp::6, _::4 <- pixel_offsets>>, do: Bytey.two_complement(alpha_temp, 6))
      |> Enum.with_index()
      |> Enum.map(fn {value, i} ->
        {x, y} = Pixels.row_and_column(i)

        value =
          value * (1 <<< acc_remnand_scale)

        value = value + :array.get(x, acc_row)
        value = value + :array.get(y, acc_col)
        value = value + alpha_ref
        value = value / 2 ** working_alpha_scale
        value = value - params.tgc * (params.cp.alpha_0 + params.cp.alpha_1) / 2
        @scale_alpha / value
      end)

    alpha_scale = alpha_temp |> Enum.max() |> alpha_scale_from_max_temp()
    alpha_scale_2pow = 2 ** alpha_scale

    alphas = Enum.map(alpha_temp, fn at -> trunc(0.5 + at * alpha_scale_2pow) end)

    %{params | alpha_scale: alpha_scale, alphas: alphas}
  end

  defp alpha_scale_from_max_temp(temp, alpha_scale \\ 0)

  defp alpha_scale_from_max_temp(temp, alpha_scale) when temp < 32_767.4 do
    alpha_scale_from_max_temp(temp * 2, alpha_scale + 1)
  end

  defp alpha_scale_from_max_temp(_, alpha_scale), do: alpha_scale

  def(read_alpha_scale(%{acc: <<alpha_scale::4, _::4>> <> _})) do
    alpha_scale
  end
end
