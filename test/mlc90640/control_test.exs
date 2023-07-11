defmodule Mlc90640.ControlTest do
  use ExUnit.Case, async: false
  alias Mlc90640.Control

  import Bitwise
  import Mox
  setup :verify_on_exit!

  alias Mlc90640.Bytey

  setup do
    Mox.set_mox_global()
    {:ok, ref: ref()}
  end

  test "starting" do
    expect(MockI2c, :open, fn "i2c-1" -> {:ok, ref()} end)
    assert {:ok, ref()} == Control.start()
  end

  test "stopping" do
    expect(MockI2c, :close, fn ref ->
      assert ref == ref()
      :ok
    end)

    assert :ok == Control.stop(ref())
  end

  test "reading the control registry", %{ref: ref} do
    expect(MockI2c, :write_read, fn ^ref, address, value, length ->
      assert 0x33 == address
      assert value == <<128, 13>>
      assert length == 2
      {:ok, <<25, 1>>}
    end)

    assert {:ok, 6401} == Control.read_control_reg1(ref())
  end

  describe "setting fps" do
    test "sets the fps", %{ref: ref} do
      expect(MockI2c, :write_read, fn ^ref, 0x33, <<128, 13>>, 2 ->
        {:ok, <<0, 0>>}
      end)

      expect(MockI2c, :write, fn ^ref, 0x33, command ->
        assert <<128, 13, value::16>> = command
        assert 0b111 == (value >>> 7 &&& 0b111)

        :ok
      end)

      assert :ok == Control.set_chessboard_and_fps(ref(), 64)
    end

    test "sets chessboard" do
      stub(MockI2c, :write_read, fn _, _, _, _ ->
        {:ok, <<0, 0>>}
      end)

      expect(MockI2c, :write, fn _, _, command ->
        assert <<128, 13, value::16>> = command
        assert 1 == (value >>> 12 &&& 1)
        :ok
      end)

      assert :ok == Control.set_chessboard_and_fps(ref(), 64)
    end
  end

  describe "read eeprom" do
    setup do
      eeprom_bytes =
        0x2400..0x273F
        |> Enum.map(&Bytey.to_unsigned_2_bytes(&1))
        |> IO.iodata_to_binary()

      {:ok, eeprom_bytes: eeprom_bytes}
    end

    test "splits into blocks", %{ref: ref, eeprom_bytes: eeprom_bytes} do
      expect(MockI2c, :write_read, fn ^ref, 0x33, command, length ->
        assert command == <<36, 0>>

        assert length == 1664
        {:ok, eeprom_bytes}
      end)

      assert {:ok,
              %{
                registers: registers,
                occ: occ,
                acc: acc,
                gain_etc: gain_etc,
                pixel_offsets: pixel_offsets
              }} = Control.read_eeprom(ref)

      assert list(0x2400, 0x240F) == Bytey.bin_to_values(registers)
      assert list(0x2410, 0x241F) == Bytey.bin_to_values(occ)
      assert list(0x2420, 0x242F) == Bytey.bin_to_values(acc)
      assert list(0x2430, 0x243F) == Bytey.bin_to_values(gain_etc)
      assert list(0x2440, 0x273F) == Bytey.bin_to_values(pixel_offsets)

      assert registers <> occ <> acc <> gain_etc <> pixel_offsets == eeprom_bytes
    end
  end

  defp list(start, finish), do: start..finish |> Enum.to_list()

  defp ref do
    :erlang.list_to_ref(~c"#Ref<0.1.2.3>")
  end
end
