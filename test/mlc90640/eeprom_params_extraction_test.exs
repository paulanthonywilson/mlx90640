defmodule Mlc90640.EepromParamsExtractionTest do
  use ExUnit.Case
  import Bitwise
  alias Mlc90640.{Bytey, Eeprom, EepromParamsExtraction, Params}

  @default_precision 1.0e-9

  describe "vdd" do
    test "extracting from data sheet example" do
      <<kv_vdd, vdd_25>> = Bytey.to_unsigned_2_bytes(0x9D68)
      eeprom = with_vdd(kv_vdd, vdd_25)
      %Params{kv_vdd: -3168, vdd_25: -13_056} = EepromParamsExtraction.vdd(%Params{}, eeprom)
    end

    test "from measurement" do
      eeprom = with_vdd(165, 129)

      assert %Params{kv_vdd: -2912, vdd_25: -12_256} ==
               EepromParamsExtraction.vdd(%Params{}, eeprom)
    end

    test "preserves any already populated params values" do
      assert %Params{v_ptat25: 11} =
               EepromParamsExtraction.vdd(%Params{v_ptat25: 11}, with_vdd(0, 0))
    end

    defp with_vdd(kv_vdd, vdd_25) do
      %Eeprom{gain_etc: <<0::48, kv_vdd, vdd_25, 0::192>>}
    end
  end

  describe "ptat" do
    test "with all blanks" do
      assert %Params{
               kv_ptat: kv_ptat,
               kt_ptat: kt_ptat,
               v_ptat25: v_ptat25,
               alpha_ptat: alpha_ptat
             } = EepromParamsExtraction.ptat(%Params{}, %Eeprom{})

      assert_in_delta kv_ptat, 0.0, @default_precision
      assert_in_delta kt_ptat, 0.0, @default_precision
      assert 0 == v_ptat25
      assert_in_delta alpha_ptat, 8.0, @default_precision
    end

    test "positive kv_ptat" do
      assert %Params{
               kv_ptat: kv_ptat
             } = EepromParamsExtraction.ptat(%Params{}, with_ptat(31, 0))

      assert_in_delta kv_ptat, 0.007568359375, @default_precision
    end

    test "negative kv_ptat" do
      assert %Params{
               kv_ptat: kv_ptat
             } = EepromParamsExtraction.ptat(%Params{}, with_ptat(33, 0))

      assert_in_delta kv_ptat, -0.007568359375, @default_precision
    end

    test "ktptat" do
      assert %Params{
               kt_ptat: kt_ptat
             } = EepromParamsExtraction.ptat(%Params{}, with_ptat(33, 511))

      assert_in_delta kt_ptat, 63.875, @default_precision
    end

    test "negative ktptat" do
      assert %Params{
               kt_ptat: kt_ptat
             } = EepromParamsExtraction.ptat(%Params{}, with_ptat(33, 513))

      assert_in_delta kt_ptat, -63.875, @default_precision
    end

    test "data sheet example kv_ptat and kt_ptat" do
      assert %Params{
               kt_ptat: kt_ptat,
               kv_ptat: kv_ptat
             } = EepromParamsExtraction.ptat(%Params{}, with_ptat(0x5952))

      assert_in_delta kt_ptat, 42.25, @default_precision
      assert_in_delta kv_ptat, 0.005371094, @default_precision
    end

    test "data sheet example ptat_25" do
      assert %Params{
               v_ptat25: 12_273
             } = EepromParamsExtraction.ptat(%Params{}, with_vptat25(0x2FF1))
    end

    test "ptat25 is 2's complement" do
      assert %Params{
               v_ptat25: 32_767
             } = EepromParamsExtraction.ptat(%Params{}, with_vptat25(32_767))

      assert %Params{
               v_ptat25: -32_768
             } = EepromParamsExtraction.ptat(%Params{}, with_vptat25(32_768))
    end

    test "alpha ptat from data sheet example" do
      assert %Params{
               alpha_ptat: alpha_ptat
             } = EepromParamsExtraction.ptat(%Params{}, with_ptat_occ_scale_16(0x4210))

      assert_in_delta alpha_ptat, 9.0, @default_precision
    end

    test "alpha ptat " do
      assert %Params{
               alpha_ptat: alpha_ptat
             } = EepromParamsExtraction.ptat(%Params{}, with_ptat_occ_scale_16(0xFFFF))

      assert_in_delta alpha_ptat, 15 / 4 + 8, @default_precision
    end

    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               EepromParamsExtraction.ptat(%Params{vdd_25: 11}, %Eeprom{})
    end

    defp with_vptat25(v_ptat25) do
      %Eeprom{gain_etc: <<0::16, v_ptat25::16, 0::224>>}
    end

    defp with_ptat(kvptat, ktptat) do
      with_ptat(bor(kvptat <<< 10, ktptat))
    end

    defp with_ptat(ptat16bit) do
      %Eeprom{gain_etc: <<0::32, ptat16bit::16, 0::208>>}
    end

    defp with_ptat_occ_scale_16(value) do
      %Eeprom{occ: <<value::16, 0::240>>}
    end
  end

  describe "gain" do
    test "using data sheet example" do
      assert %Params{
               gain: 6383
             } = EepromParamsExtraction.gain(%Params{}, with_gain(0x18EF))
    end

    test "is two's complement" do
      assert %Params{
               gain: 32_767
             } = EepromParamsExtraction.gain(%Params{}, with_gain(32_767))

      assert %Params{
               gain: -32_768
             } = EepromParamsExtraction.gain(%Params{}, with_gain(32_768))
    end

    test "preserves existing params" do
      assert %Params{vdd_25: 11} =
               EepromParamsExtraction.gain(%Params{vdd_25: 11}, %Eeprom{})
    end

    defp with_gain(value) do
      %Eeprom{gain_etc: <<value::16, 0::240>>}
    end
  end

  describe "tgc" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               EepromParamsExtraction.tgc(%Params{vdd_25: 11}, %Eeprom{})
    end

    test "with data sheet example" do
      assert %Params{tgc: tgc} = EepromParamsExtraction.tgc(%Params{}, with_ksta_tgc(0xF020))
      assert_in_delta tgc, 1.0, @default_precision
    end

    test "2's complement tgc in data" do
      assert %Params{tgc: tgc} = EepromParamsExtraction.tgc(%Params{}, with_ksta_tgc(0x007F))
      assert_in_delta tgc, 127 / 32, @default_precision

      assert %Params{tgc: tgc} = EepromParamsExtraction.tgc(%Params{}, with_ksta_tgc(0x0080))
      assert_in_delta tgc, -128 / 32, @default_precision
    end
  end

  describe "ksta" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               EepromParamsExtraction.ksta(%Params{vdd_25: 11}, %Eeprom{})
    end

    test "with data sheet example" do
      assert %Params{ksta: ksta} = EepromParamsExtraction.ksta(%Params{}, with_ksta_tgc(0xF020))
      assert_in_delta ksta, -0.001953125, @default_precision
    end

    test "2's complement" do
      assert %Params{ksta: ksta} = EepromParamsExtraction.ksta(%Params{}, with_ksta_tgc(0x7F00))
      assert_in_delta ksta, 127 / 8192.0, @default_precision
      assert %Params{ksta: ksta} = EepromParamsExtraction.ksta(%Params{}, with_ksta_tgc(0x8000))
      assert_in_delta ksta, -128 / 8192.0, @default_precision
    end
  end

  describe "ksto" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               EepromParamsExtraction.ksto(%Params{vdd_25: 11}, %Eeprom{})
    end

    test "with data sheet example" do
      assert %Params{
               ks_to: %{
                 ks_to_0: ks_to_0,
                 ks_to_1: ks_to_1,
                 ks_to_2: ks_to_2,
                 ks_to_3: ks_to_3,
                 ks_to_4: ks_to_4,
                 ct_0: -40,
                 ct_1: 0,
                 ct_2: 160,
                 ct_3: 320,
                 ct_4: 400,
                 step: 20,
                 ks_to_scale: 17
               }
             } = EepromParamsExtraction.ksto(%Params{}, with_ksto(0x9797, 0x9797, 0x2889))

      assert_in_delta ks_to_0, -0.0008010864, @default_precision
      assert_in_delta ks_to_1, -0.0008010864, @default_precision
      assert_in_delta ks_to_2, -0.0008010864, @default_precision
      assert_in_delta ks_to_3, -0.0008010864, @default_precision
      assert_in_delta ks_to_4, -0.0002, @default_precision
    end

    test "with varied ct and step" do
      assert %{ks_to: %{ct_2: 110, ct_3: 210, step: 10}} =
               EepromParamsExtraction.ksto(%Params{}, with_ksto(0, 0, 0x01AB1))
    end

    test "varying ks_scale" do
      assert %{
               ks_to: %{
                 ks_to_0: ks_to_0,
                 ks_to_1: ks_to_1,
                 ks_to_2: ks_to_2,
                 ks_to_3: ks_to_3,
                 ks_to_4: ks_to_4,
                 ks_to_scale: 13
               }
             } =
               EepromParamsExtraction.ksto(%Params{}, with_ksto(0x9797, 0x9797, 0x5))

      assert_in_delta ks_to_0, -0.0128173828125, @default_precision
      assert_in_delta ks_to_1, -0.0128173828125, @default_precision
      assert_in_delta ks_to_2, -0.0128173828125, @default_precision
      assert_in_delta ks_to_3, -0.0128173828125, @default_precision
      assert_in_delta ks_to_4, -0.0002, @default_precision
    end

    test "positive configured ks values" do
      assert %{
               ks_to: %{
                 ks_to_0: ks_to_0,
                 ks_to_1: ks_to_1,
                 ks_to_2: ks_to_2,
                 ks_to_3: ks_to_3,
                 ks_to_4: ks_to_4,
                 ks_to_scale: 8
               }
             } =
               EepromParamsExtraction.ksto(%Params{}, with_ksto(0x7E7F, 0x7C7D, 0))

      assert_in_delta ks_to_0, 127 / 256, @default_precision
      assert_in_delta ks_to_1, 126 / 256, @default_precision
      assert_in_delta ks_to_2, 125 / 256, @default_precision
      assert_in_delta ks_to_3, 124 / 256, @default_precision
      assert_in_delta ks_to_4, -0.0002, @default_precision
    end

    defp with_ksto(ksto2_1, ksto_4_3, ct) do
      %Eeprom{gain_etc: <<0::208, ksto2_1::16, ksto_4_3::16, ct::16>>}
    end
  end

  test "reading alpha scale" do
    for i <- 0..0xF do
      eeprom = %Eeprom{acc: <<i::4, 0::252>>}
      assert i + 27 == EepromParamsExtraction.read_alpha_scale(eeprom)
    end
  end

  defp with_ksta_tgc(ksta_tgc) do
    %Eeprom{gain_etc: <<0::192, ksta_tgc::16, 0::48>>}
  end
end
