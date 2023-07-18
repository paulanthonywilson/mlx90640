defmodule Mlc90640.EepromParamsExtraction do
  @moduledoc false
  _doc = """
  Extracts parameters from the eeprom that has been read
  """

  import Bitwise

  alias Mlc90640.{Bytey, Eeprom, Mathy, Params, Pixels}

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

    {acc_row, acc_col} = row_cols(acc_row_cols_bin, acc_row_scale, acc_col_scale)

    alpha_temp =
      for_each_pixel_param(pixel_offsets, 6, 6, fn value, _i, x, y ->
        value =
          value * (1 <<< acc_remnand_scale)

        value = value + :array.get(x, acc_row)
        value = value + :array.get(y, acc_col)
        value = value + alpha_ref
        value = value / 2 ** working_alpha_scale
        value = value - params.tgc * (params.cp.alpha_0 + params.cp.alpha_1) / 2
        @scale_alpha / value
      end)

    alpha_scale = alpha_temp |> Enum.max() |> Mathy.maximum_doubling_while_less_than(32_767.4)
    alpha_scale_2pow = 2 ** alpha_scale

    alphas = Enum.map(alpha_temp, fn at -> trunc(0.5 + at * alpha_scale_2pow) end)

    %{params | alpha_scale: alpha_scale, alphas: alphas}
  end

  @spec offsets(Params.t(), Eeprom.t()) :: Params.t()
  def offsets(params, %{occ: occ, pixel_offsets: pixel_offsets}) do
    <<_::4, occ_row_scale::4, occ_col_scale::4, occ_rem_scale::4, offset_ref::16>> <> occ_row_cols =
      occ

    occ_rem_scale = 2 ** occ_rem_scale
    offset_ref = Bytey.two_complement(offset_ref)
    {occ_rows, occ_cols} = row_cols(occ_row_cols, occ_row_scale, occ_col_scale)

    offsets =
      for_each_pixel_param(pixel_offsets, 0, 6, fn value, _i, x, y ->
        value = value * occ_rem_scale
        value = value + offset_ref
        value = value + :array.get(x, occ_rows)
        value + :array.get(y, occ_cols)
      end)

    %{params | offsets: offsets}
  end

  @spec kta_pixels(Params.t(), Eeprom.t()) :: Params.t()
  def kta_pixels(params, %{gain_etc: gain_etc, pixel_offsets: pixel_offsets}) do
    <<_::96, rc_0::8, rc_2::8, rc_1::8, rc_3::8, _::8, kta_scale_1::4, kta_scale_2::4>> <> _ =
      gain_etc

    rcs =
      Enum.map([rc_0, rc_1, rc_2, rc_3], &Bytey.two_complement(&1, 8))

    kta_scale_1 = 2 ** (8 + kta_scale_1)
    kta_scale_2 = 2 ** kta_scale_2

    ktas =
      for_each_pixel_param(pixel_offsets, 12, 3, fn value, i, _x, _y ->
        value = value * kta_scale_2
        value = value + Enum.at(rcs, pixel_index_to_odd_even_split(i))
        value / kta_scale_1
      end)

    kta_scale = ktas |> Mathy.abs_max() |> Mathy.maximum_doubling_while_less_than(63.4)
    two_pow_kta_scale = 2 ** kta_scale

    ktas =
      Enum.map(ktas, fn value ->
        Mathy.round_to_int(value * two_pow_kta_scale)
      end)

    %{params | kta_scale: kta_scale, ktas: ktas}
  end

  @spec kv_pixels(Params.t(), Eeprom.t()) :: Params.t()
  def kv_pixels(params, %{gain_etc: gain_etc}) do
    <<_::64, rc_0::4, rc_2::4, rc_1::4, rc_3::4, _::52, scale::4>> <> _ = gain_etc
    rcs = Enum.map([rc_0, rc_1, rc_2, rc_3], &Bytey.two_complement(&1, 4))
    scale = 2 ** scale

    kvs =
      for i <- 0..(Pixels.pixel_count() - 1) do
        Enum.at(rcs, pixel_index_to_odd_even_split(i)) / scale
      end

    kv_scale = Mathy.abs_max(kvs) |> Mathy.maximum_doubling_while_less_than(63.4)
    two_pow_kv_scale = 2 ** kv_scale

    kvs =
      Enum.map(kvs, fn value ->
        Mathy.round_to_int(value * two_pow_kv_scale)
      end)

    %{params | kv_scale: kv_scale, kvs: kvs}
  end

  defp pixel_index_to_odd_even_split(i) do
    2 * (Integer.floor_div(i, 32) - Integer.floor_div(i, 64) * 2) + rem(i, 2)
  end

  defp for_each_pixel_param(pixel_params, bit_start, bit_length, fun) do
    for <<_::size(bit_start), param::size(bit_length),
          _::size(16 - bit_start - bit_length) <- pixel_params>> do
      Bytey.two_complement(param, bit_length)
    end
    |> Enum.with_index()
    |> Enum.map(fn {value, i} ->
      {x, y} = Pixels.row_and_column(i)
      fun.(value, i, x, y)
    end)
  end

  defp row_cols(bin_row_cols, row_scale, col_scale) do
    {rows, cols} =
      bin_row_cols
      |> Bytey.bin_to_values(4)
      |> Enum.map(&Bytey.two_complement(&1, 4))
      |> Enum.chunk_every(4)
      |> Enum.map(&Enum.reverse/1)
      |> List.flatten()
      |> Enum.split(Pixels.row_count())

    row =
      rows
      |> Enum.map(&(&1 <<< row_scale))
      |> :array.from_list()

    col =
      cols
      |> Enum.map(&(&1 <<< col_scale))
      |> :array.from_list()

    {row, col}
  end

  def(read_alpha_scale(%{acc: <<alpha_scale::4, _::4>> <> _})) do
    alpha_scale
  end
end
