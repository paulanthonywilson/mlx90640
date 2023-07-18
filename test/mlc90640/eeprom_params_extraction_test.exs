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
      assert i == EepromParamsExtraction.read_alpha_scale(eeprom)
    end
  end

  describe "extract cpp parameters" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} = EepromParamsExtraction.cp(%Params{vdd_25: 11}, %Eeprom{})
    end

    test "matches the library extraction on a device" do
      assert %{
               cp: %{
                 kv: kv,
                 kta: kta,
                 alpha_0: alpha_0,
                 alpha_1: alpha_1,
                 offset_0: -68,
                 offset_1: -62
               }
             } = EepromParamsExtraction.cp(%Params{}, ExampleEeprom.eeprom())

      assert_in_delta kv, 0.375, @default_precision
      assert_in_delta kta, 4.455566e-03, @default_precision
      assert_in_delta alpha_0, 4.016329e-9, 1.0e-12
      assert_in_delta alpha_1, 3.953573e-9, 1.0e-12
    end

    test "negative kta" do
      eeprom = (59 * 2 + 1) |> ExampleEeprom.substitute_raw_bytes(<<0xFF>>) |> Eeprom.new()
      assert %{cp: %{kta: kta}} = EepromParamsExtraction.cp(%Params{}, eeprom)
      assert_in_delta kta, -6.103515625e-5, @default_precision
    end

    test "negative kv" do
      eeprom = (59 * 2) |> ExampleEeprom.substitute_raw_bytes(<<0xFF>>) |> Eeprom.new()
      assert %{cp: %{kv: kv}} = EepromParamsExtraction.cp(%Params{}, eeprom)
      assert_in_delta kv, -0.125, @default_precision
    end

    test "positive offsets" do
      eeprom = (58 * 2) |> ExampleEeprom.substitute_raw_bytes(<<31::6, 511::10>>) |> Eeprom.new()

      assert %{
               cp: %{offset_0: 511, offset_1: 542}
             } = EepromParamsExtraction.cp(%Params{}, eeprom)
    end

    test "positive alphas" do
      eeprom = (57 * 2) |> ExampleEeprom.substitute_raw_bytes(<<31::6, 511::10>>) |> Eeprom.new()

      assert %{cp: %{alpha_0: alpha_0, alpha_1: alpha_1}} =
               EepromParamsExtraction.cp(%Params{}, eeprom)

      assert_in_delta alpha_0,
                      511 / 2 ** (27 + EepromParamsExtraction.read_alpha_scale(eeprom)),
                      1.0e-12

      assert_in_delta alpha_1, (1 + 31 / 128) * alpha_0, 1.0e-15
    end
  end

  describe "alpha" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} = alphas_from_melixis_lib(%Params{vdd_25: 11})
    end

    test "matches the melixis library alpha scale" do
      assert %{alpha_scale: 11} = alphas_from_melixis_lib()
    end

    test "matches the melixis library alphas" do
      assert %{alphas: alphas} = alphas_from_melixis_lib()

      assert Enum.take(alphas, 20) == Enum.take(ExampleEeprom.expected_alphas(), 20)
      assert alphas == ExampleEeprom.expected_alphas()
    end

    defp alphas_from_melixis_lib(params \\ %Params{}) do
      eeprom = ExampleEeprom.eeprom()

      params
      |> EepromParamsExtraction.tgc(eeprom)
      |> EepromParamsExtraction.cp(eeprom)
      |> EepromParamsExtraction.alpha(ExampleEeprom.eeprom())
    end
  end

  describe "offsets" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} = EepromParamsExtraction.offsets(%Params{vdd_25: 11}, %Eeprom{})
    end

    test "matches the output from the melixis library" do
      assert %{offsets: offsets} =
               EepromParamsExtraction.offsets(%Params{}, ExampleEeprom.eeprom())

      assert Enum.take(offsets, 10) == Enum.take(ExampleEeprom.expected_offsets(), 10)
      assert offsets == ExampleEeprom.expected_offsets()
    end

    test "with non-zero rem scale" do
      %{occ: occ} = eeprom = ExampleEeprom.eeprom()
      <<_::8, col_scale::4, _::4>> <> _ = occ

      # make rem scale 3, which will multiple by 2 to the power of 3, being 8
      scale2 = col_scale * 16 + 3
      eeprom = %{eeprom | occ: binary_part(occ, 0, 1) <> <<scale2::8>> <> binary_part(occ, 2, 30)}

      # The first pixel offset in Eeprom is 3. The scaled result for that pixel is -42.
      # We'll just prove that below
      assert %{pixel_offsets: <<3::6, _::2>> <> _} = eeprom
      assert [-42 | _] = ExampleEeprom.expected_offsets()

      # with multiplying by 9 we now expect the value to be
      # = -41 + (3 * 8) - 3
      # = -41 + 24 - 3
      # = -41 + 21
      # = -21
      assert %{offsets: [-21 | _]} =
               EepromParamsExtraction.offsets(%Params{}, eeprom)
    end
  end

  describe "kta_pixels" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               EepromParamsExtraction.kta_pixels(%Params{vdd_25: 11}, ExampleEeprom.eeprom())
    end

    test "kta scale" do
      assert %Params{kta_scale: 14} =
               EepromParamsExtraction.kta_pixels(%Params{}, ExampleEeprom.eeprom())
    end

    test "ktas match those calculated by the Melixis library" do
      assert %Params{ktas: ktas} =
               EepromParamsExtraction.kta_pixels(%Params{}, ExampleEeprom.eeprom())

      assert Enum.take(ktas, 10) == Enum.take(ExampleEeprom.expected_ktas(), 10)
      assert ktas == ExampleEeprom.expected_ktas()
    end

    test "ktas with a negative kta rc 0" do
      %{gain_etc: gain_etc} = eeprom = ExampleEeprom.eeprom()

      eeprom = %{
        eeprom
        | gain_etc:
            binary_part(gain_etc, 0, 12) <>
              <<0xFF>> <>
              binary_part(gain_etc, 13, byte_size(gain_etc) - 13)
      }

      assert %Params{kta_scale: kta_scale, ktas: ktas} =
               EepromParamsExtraction.kta_pixels(%Params{}, eeprom)

      assert kta_scale == 14
      assert Enum.take(ktas, 10) == Enum.take(ExampleEeprom.ktas_with_negative_rc_0(), 10)
      assert ktas == ExampleEeprom.ktas_with_negative_rc_0()
    end
  end

  defp with_ksta_tgc(ksta_tgc) do
    %Eeprom{gain_etc: <<0::192, ksta_tgc::16, 0::48>>}
  end
end
