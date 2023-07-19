defmodule Mlc90640.Eeprom.ParamsExtractionTest do
  use ExUnit.Case
  import Bitwise
  alias Mlc90640.{Bytey, Eeprom.ParamsExtraction}
  alias Mlc90640.Eeprom.{Params, Partitioned}

  @default_precision 1.0e-9

  describe "vdd" do
    test "extracting from data sheet example" do
      <<kv_vdd, vdd_25>> = Bytey.to_unsigned_2_bytes(0x9D68)
      eeprom = with_vdd(kv_vdd, vdd_25)
      %Params{kv_vdd: -3168, vdd_25: -13_056} = ParamsExtraction.vdd(%Params{}, eeprom)
    end

    test "from measurement" do
      eeprom = with_vdd(165, 129)

      assert %Params{kv_vdd: -2912, vdd_25: -12_256} ==
               ParamsExtraction.vdd(%Params{}, eeprom)
    end

    test "preserves any already populated params values" do
      assert %Params{v_ptat25: 11} =
               ParamsExtraction.vdd(%Params{v_ptat25: 11}, with_vdd(0, 0))
    end

    defp with_vdd(kv_vdd, vdd_25) do
      %Partitioned{gain_etc: <<0::48, kv_vdd, vdd_25, 0::192>>}
    end
  end

  describe "ptat" do
    test "with all blanks" do
      assert %Params{
               kv_ptat: kv_ptat,
               kt_ptat: kt_ptat,
               v_ptat25: v_ptat25,
               alpha_ptat: alpha_ptat
             } = ParamsExtraction.ptat(%Params{}, %Partitioned{})

      assert_in_delta kv_ptat, 0.0, @default_precision
      assert_in_delta kt_ptat, 0.0, @default_precision
      assert 0 == v_ptat25
      assert_in_delta alpha_ptat, 8.0, @default_precision
    end

    test "positive kv_ptat" do
      assert %Params{
               kv_ptat: kv_ptat
             } = ParamsExtraction.ptat(%Params{}, with_ptat(31, 0))

      assert_in_delta kv_ptat, 0.007568359375, @default_precision
    end

    test "negative kv_ptat" do
      assert %Params{
               kv_ptat: kv_ptat
             } = ParamsExtraction.ptat(%Params{}, with_ptat(33, 0))

      assert_in_delta kv_ptat, -0.007568359375, @default_precision
    end

    test "ktptat" do
      assert %Params{
               kt_ptat: kt_ptat
             } = ParamsExtraction.ptat(%Params{}, with_ptat(33, 511))

      assert_in_delta kt_ptat, 63.875, @default_precision
    end

    test "negative ktptat" do
      assert %Params{
               kt_ptat: kt_ptat
             } = ParamsExtraction.ptat(%Params{}, with_ptat(33, 513))

      assert_in_delta kt_ptat, -63.875, @default_precision
    end

    test "data sheet example kv_ptat and kt_ptat" do
      assert %Params{
               kt_ptat: kt_ptat,
               kv_ptat: kv_ptat
             } = ParamsExtraction.ptat(%Params{}, with_ptat(0x5952))

      assert_in_delta kt_ptat, 42.25, @default_precision
      assert_in_delta kv_ptat, 0.005371094, @default_precision
    end

    test "data sheet example ptat_25" do
      assert %Params{
               v_ptat25: 12_273
             } = ParamsExtraction.ptat(%Params{}, with_vptat25(0x2FF1))
    end

    test "ptat25 is 2's complement" do
      assert %Params{
               v_ptat25: 32_767
             } = ParamsExtraction.ptat(%Params{}, with_vptat25(32_767))

      assert %Params{
               v_ptat25: -32_768
             } = ParamsExtraction.ptat(%Params{}, with_vptat25(32_768))
    end

    test "alpha ptat from data sheet example" do
      assert %Params{
               alpha_ptat: alpha_ptat
             } = ParamsExtraction.ptat(%Params{}, with_ptat_occ_scale_16(0x4210))

      assert_in_delta alpha_ptat, 9.0, @default_precision
    end

    test "alpha ptat " do
      assert %Params{
               alpha_ptat: alpha_ptat
             } = ParamsExtraction.ptat(%Params{}, with_ptat_occ_scale_16(0xFFFF))

      assert_in_delta alpha_ptat, 15 / 4 + 8, @default_precision
    end

    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               ParamsExtraction.ptat(%Params{vdd_25: 11}, %Partitioned{})
    end

    defp with_vptat25(v_ptat25) do
      %Partitioned{gain_etc: <<0::16, v_ptat25::16, 0::224>>}
    end

    defp with_ptat(kvptat, ktptat) do
      with_ptat(bor(kvptat <<< 10, ktptat))
    end

    defp with_ptat(ptat16bit) do
      %Partitioned{gain_etc: <<0::32, ptat16bit::16, 0::208>>}
    end

    defp with_ptat_occ_scale_16(value) do
      %Partitioned{occ: <<value::16, 0::240>>}
    end
  end

  describe "gain" do
    test "using data sheet example" do
      assert %Params{
               gain: 6383
             } = ParamsExtraction.gain(%Params{}, with_gain(0x18EF))
    end

    test "is two's complement" do
      assert %Params{
               gain: 32_767
             } = ParamsExtraction.gain(%Params{}, with_gain(32_767))

      assert %Params{
               gain: -32_768
             } = ParamsExtraction.gain(%Params{}, with_gain(32_768))
    end

    test "preserves existing params" do
      assert %Params{vdd_25: 11} =
               ParamsExtraction.gain(%Params{vdd_25: 11}, %Partitioned{})
    end

    defp with_gain(value) do
      %Partitioned{gain_etc: <<value::16, 0::240>>}
    end
  end

  describe "tgc" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               ParamsExtraction.tgc(%Params{vdd_25: 11}, %Partitioned{})
    end

    test "with data sheet example" do
      assert %Params{tgc: tgc} = ParamsExtraction.tgc(%Params{}, with_ksta_tgc(0xF020))
      assert_in_delta tgc, 1.0, @default_precision
    end

    test "2's complement tgc in data" do
      assert %Params{tgc: tgc} = ParamsExtraction.tgc(%Params{}, with_ksta_tgc(0x007F))
      assert_in_delta tgc, 127 / 32, @default_precision

      assert %Params{tgc: tgc} = ParamsExtraction.tgc(%Params{}, with_ksta_tgc(0x0080))
      assert_in_delta tgc, -128 / 32, @default_precision
    end
  end

  describe "ksta" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               ParamsExtraction.ksta(%Params{vdd_25: 11}, %Partitioned{})
    end

    test "with data sheet example" do
      assert %Params{ksta: ksta} = ParamsExtraction.ksta(%Params{}, with_ksta_tgc(0xF020))
      assert_in_delta ksta, -0.001953125, @default_precision
    end

    test "2's complement" do
      assert %Params{ksta: ksta} = ParamsExtraction.ksta(%Params{}, with_ksta_tgc(0x7F00))
      assert_in_delta ksta, 127 / 8192.0, @default_precision
      assert %Params{ksta: ksta} = ParamsExtraction.ksta(%Params{}, with_ksta_tgc(0x8000))
      assert_in_delta ksta, -128 / 8192.0, @default_precision
    end
  end

  describe "ksto" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               ParamsExtraction.ksto(%Params{vdd_25: 11}, %Partitioned{})
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
             } = ParamsExtraction.ksto(%Params{}, with_ksto(0x9797, 0x9797, 0x2889))

      assert_in_delta ks_to_0, -0.0008010864, @default_precision
      assert_in_delta ks_to_1, -0.0008010864, @default_precision
      assert_in_delta ks_to_2, -0.0008010864, @default_precision
      assert_in_delta ks_to_3, -0.0008010864, @default_precision
      assert_in_delta ks_to_4, -0.0002, @default_precision
    end

    test "with varied ct and step" do
      assert %{ks_to: %{ct_2: 110, ct_3: 210, step: 10}} =
               ParamsExtraction.ksto(%Params{}, with_ksto(0, 0, 0x01AB1))
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
               ParamsExtraction.ksto(%Params{}, with_ksto(0x9797, 0x9797, 0x5))

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
               ParamsExtraction.ksto(%Params{}, with_ksto(0x7E7F, 0x7C7D, 0))

      assert_in_delta ks_to_0, 127 / 256, @default_precision
      assert_in_delta ks_to_1, 126 / 256, @default_precision
      assert_in_delta ks_to_2, 125 / 256, @default_precision
      assert_in_delta ks_to_3, 124 / 256, @default_precision
      assert_in_delta ks_to_4, -0.0002, @default_precision
    end

    defp with_ksto(ksto2_1, ksto_4_3, ct) do
      %Partitioned{gain_etc: <<0::208, ksto2_1::16, ksto_4_3::16, ct::16>>}
    end
  end

  test "reading alpha scale" do
    for i <- 0..0xF do
      eeprom = %Partitioned{acc: <<i::4, 0::252>>}
      assert i == ParamsExtraction.read_alpha_scale(eeprom)
    end
  end

  describe "extract cpp parameters" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} = ParamsExtraction.cp(%Params{vdd_25: 11}, %Partitioned{})
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
             } = ParamsExtraction.cp(%Params{}, ExampleEeprom.eeprom())

      assert_in_delta kv, 0.375, @default_precision
      assert_in_delta kta, 4.455566e-03, @default_precision
      assert_in_delta alpha_0, 4.016329e-9, 1.0e-12
      assert_in_delta alpha_1, 3.953573e-9, 1.0e-12
    end

    test "negative kta" do
      eeprom = (59 * 2 + 1) |> ExampleEeprom.substitute_raw_bytes(<<0xFF>>) |> Partitioned.new()
      assert %{cp: %{kta: kta}} = ParamsExtraction.cp(%Params{}, eeprom)
      assert_in_delta kta, -6.103515625e-5, @default_precision
    end

    test "negative kv" do
      eeprom = (59 * 2) |> ExampleEeprom.substitute_raw_bytes(<<0xFF>>) |> Partitioned.new()
      assert %{cp: %{kv: kv}} = ParamsExtraction.cp(%Params{}, eeprom)
      assert_in_delta kv, -0.125, @default_precision
    end

    test "positive offsets" do
      eeprom =
        (58 * 2) |> ExampleEeprom.substitute_raw_bytes(<<31::6, 511::10>>) |> Partitioned.new()

      assert %{
               cp: %{offset_0: 511, offset_1: 542}
             } = ParamsExtraction.cp(%Params{}, eeprom)
    end

    test "positive alphas" do
      eeprom =
        (57 * 2) |> ExampleEeprom.substitute_raw_bytes(<<31::6, 511::10>>) |> Partitioned.new()

      assert %{cp: %{alpha_0: alpha_0, alpha_1: alpha_1}} =
               ParamsExtraction.cp(%Params{}, eeprom)

      assert_in_delta alpha_0,
                      511 / 2 ** (27 + ParamsExtraction.read_alpha_scale(eeprom)),
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
      |> ParamsExtraction.tgc(eeprom)
      |> ParamsExtraction.cp(eeprom)
      |> ParamsExtraction.alpha(ExampleEeprom.eeprom())
    end
  end

  describe "offsets" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} = ParamsExtraction.offsets(%Params{vdd_25: 11}, %Partitioned{})
    end

    test "matches the output from the melixis library" do
      assert %{offsets: offsets} =
               ParamsExtraction.offsets(%Params{}, ExampleEeprom.eeprom())

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
               ParamsExtraction.offsets(%Params{}, eeprom)
    end
  end

  describe "kta_pixels" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               ParamsExtraction.kta_pixels(%Params{vdd_25: 11}, ExampleEeprom.eeprom())
    end

    test "scale" do
      assert %Params{kta_scale: 14} =
               ParamsExtraction.kta_pixels(%Params{}, ExampleEeprom.eeprom())
    end

    test "match those calculated by the Melixis library" do
      assert %Params{ktas: ktas} =
               ParamsExtraction.kta_pixels(%Params{}, ExampleEeprom.eeprom())

      assert Enum.take(ktas, 10) == Enum.take(ExampleEeprom.expected_ktas(), 10)
      assert ktas == ExampleEeprom.expected_ktas()
    end

    test "with a negative kta rc 0" do
      %{gain_etc: gain_etc} = eeprom = ExampleEeprom.eeprom()

      eeprom = %{
        eeprom
        | gain_etc:
            binary_part(gain_etc, 0, 12) <>
              <<0xFF>> <>
              binary_part(gain_etc, 13, byte_size(gain_etc) - 13)
      }

      assert %Params{kta_scale: kta_scale, ktas: ktas} =
               ParamsExtraction.kta_pixels(%Params{}, eeprom)

      assert kta_scale == 14
      assert Enum.take(ktas, 10) == Enum.take(ExampleEeprom.ktas_with_negative_rc_0(), 10)
      assert ktas == ExampleEeprom.ktas_with_negative_rc_0()
      assert ktas |> hd() |> is_integer()
    end
  end

  describe "kv pixels" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               ParamsExtraction.kv_pixels(%Params{vdd_25: 11}, ExampleEeprom.eeprom())
    end

    test "scale" do
      assert %Params{kv_scale: kv_scale} =
               ParamsExtraction.kv_pixels(%Params{}, ExampleEeprom.eeprom())

      assert 7 == kv_scale
    end

    test "match those calculated by the Melixis library" do
      assert %Params{kvs: kvs} =
               ParamsExtraction.kv_pixels(%Params{}, ExampleEeprom.eeprom())

      assert Enum.take(kvs, 10) == Enum.take(ExampleEeprom.expected_kvs(), 10)
      assert kvs == ExampleEeprom.expected_kvs()
      assert kvs |> hd() |> is_integer()
    end

    test "matches with Melixis library when rc_0 is tweaked to be negative" do
      %{gain_etc: gain_etc} = eeprom = ExampleEeprom.eeprom()
      <<_::68, rc_2::4>> <> _ = gain_etc

      eeprom = %{
        eeprom
        | gain_etc:
            binary_part(gain_etc, 0, 8) <>
              <<0xF::4, rc_2::4>> <> binary_part(gain_etc, 9, byte_size(gain_etc) - 9)
      }

      assert %Params{kvs: kvs, kv_scale: kv_scale} =
               ParamsExtraction.kv_pixels(%Params{}, eeprom)

      assert(Enum.take(kvs, 10) == Enum.take(ExampleEeprom.kvs_with_negative_rc_0(), 10))

      assert kvs == ExampleEeprom.kvs_with_negative_rc_0()
      assert 8 = kv_scale
    end
  end

  describe "cilc" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               ParamsExtraction.cilc(%Params{vdd_25: 11}, ExampleEeprom.eeprom())
    end

    test "matches with Melixis library output" do
      assert %Params{calibration_mode_ee: calibration, il_chess_c: il_chess_c} =
               ParamsExtraction.cilc(%Params{}, ExampleEeprom.eeprom())

      assert 128 = calibration
      {chess0, chess1, chess2} = il_chess_c
      assert_in_delta 0.5, chess0, @default_precision
      assert_in_delta 3.5, chess1, @default_precision
      assert_in_delta -0.25, chess2, @default_precision
    end

    test "other calibration mode ee" do
      assert %{calibration_mode_ee: calibration} =
               ParamsExtraction.cilc(%Params{}, %Partitioned{
                 registers: <<0::160, 0xFFFF, 0::80>>
               })

      assert 0 = calibration
    end

    test "just positive il_chess_values" do
      chess_bin = <<15::5, 15::5, 31::6>>

      assert %{il_chess_c: {chess_0, chess_1, chess_2}} =
               ParamsExtraction.cilc(
                 %Params{},
                 %Partitioned{
                   gain_etc: <<0::80>> <> chess_bin <> <<0::160>>
                 }
               )

      assert_in_delta 31 / 16, chess_0, @default_precision
      assert_in_delta 15 / 2, chess_1, @default_precision
      assert_in_delta 15 / 8, chess_2, @default_precision
    end

    test "just negative il_chess_values" do
      chess_bin = <<16::5, 16::5, 32::6>>

      assert %{il_chess_c: {chess_0, chess_1, chess_2}} =
               ParamsExtraction.cilc(
                 %Params{},
                 %Partitioned{
                   gain_etc: <<0::80>> <> chess_bin <> <<0::160>>
                 }
               )

      assert_in_delta -32 / 16, chess_0, @default_precision
      assert_in_delta -16 / 2, chess_1, @default_precision
      assert_in_delta -16 / 8, chess_2, @default_precision
    end
  end

  describe "deviating pixels" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               ParamsExtraction.deviants(%Params{vdd_25: 11}, ExampleEeprom.eeprom())
    end

    test "detects no anomalies when using the example snapshot from sensors" do
      # On the one hand it's great that neither of the sensors I bought from Pimoroni have
      # any defects in their pixels. On the other hand this test is not too helpful
      assert %Params{broken_pixels: [], outlier_pixels: []} =
               ParamsExtraction.deviants(%Params{}, ExampleEeprom.eeprom())
    end

    test "detects anomalous pixels" do
      eeprom = %{pixel_offsets: pixels} = ExampleEeprom.eeprom()
      pixels = binary_part(pixels, 0, 1528) <> <<0::16, 1::16, 0::16, 0x12FF::16>>

      assert %Params{broken_pixels: broken, outlier_pixels: outliers} =
               ParamsExtraction.deviants(%Params{}, %{eeprom | pixel_offsets: pixels})

      assert [766, 764] = broken
      assert [767, 765] = outliers
    end
  end

  describe "resolution pixels" do
    test "preserves any already populated params values" do
      assert %Params{vdd_25: 11} =
               ParamsExtraction.resolution(%Params{vdd_25: 11}, ExampleEeprom.eeprom())
    end

    test "matches resolution detected by the Melixis lib" do
      assert %Params{resolution_ee: 2} =
               ParamsExtraction.resolution(%Params{}, ExampleEeprom.eeprom())
    end

    test "works with a different value" do
      eeprom = %Partitioned{
        gain_etc: <<0::130, 3::2, 0::124>>
      }

      assert %Params{resolution_ee: 3} = ParamsExtraction.resolution(%Params{}, eeprom)
    end
  end

  defp with_ksta_tgc(ksta_tgc) do
    %Partitioned{gain_etc: <<0::192, ksta_tgc::16, 0::48>>}
  end
end
