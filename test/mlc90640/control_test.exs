defmodule Mlc90640.ControlTest do
  use ExUnit.Case, async: false
  alias Mlc90640.Control

  import Bitwise
  import Mox
  setup :verify_on_exit!

  alias Mlc90640.Eeprom.Params

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

  describe "reading the control registry" do
    test "returns the control registry value", %{ref: ref} do
      expect(MockI2c, :write_read, fn ^ref, address, value, length ->
        assert 0x33 == address
        assert value == <<128, 13>>
        assert length == 2
        {:ok, <<25, 1>>}
      end)

      assert {:ok, 6401} == Control.read_control_reg1(ref)
    end

    test "returns the error on failure" do
      stub(MockI2c, :write_read, fn _, _, _, _ ->
        {:error, "oh oh"}
      end)

      assert {:error, "oh oh"} = Control.read_control_reg1(ref())
    end
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

      assert :ok == Control.set_chessboard_and_fps(ref, 64)
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

    test "returns the error on failure to read" do
      stub(MockI2c, :write_read, fn _, _, _, _ ->
        {:error, "oh oh"}
      end)

      assert {:error, "oh oh"} == Control.set_chessboard_and_fps(ref(), 64)
    end

    test "returns the error on failure to write" do
      stub(MockI2c, :write_read, fn _, _, _, _ ->
        {:ok, <<0, 0>>}
      end)

      stub(MockI2c, :write, fn _, _, _ ->
        {:error, "oh boy"}
      end)

      assert {:error, "oh boy"} == Control.set_chessboard_and_fps(ref(), 64)
    end
  end

  describe "read eeprom" do
    test "splits into blocks", %{ref: ref} do
      expect(MockI2c, :write_read, fn ^ref, 0x33, command, length ->
        assert command == <<36, 0>>

        assert length == 1664
        {:ok, ExampleEeprom.raw_eeprom()}
      end)

      assert {:ok, params} =
               Control.read_eeprom(ref)

      assert %Params{v_ptat25: 12_203} = params
    end

    test "returns error if fails" do
      stub(MockI2c, :write_read, fn _, _, _, _ ->
        {:error, "some bad thing"}
      end)

      assert {:error, "some bad thing"} = Control.read_eeprom(ref())
    end
  end

  defp ref do
    :erlang.list_to_ref(~c"#Ref<0.1.2.3>")
  end
end
