defmodule Mlc90640.ControlTest do
  use ExUnit.Case, async: false
  alias Mlc90640.Control

  import Bitwise
  import Mox
  setup :verify_on_exit!

  setup do
    Mox.set_mox_global()
    :ok
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

  test "reading the control registry" do
    expect(MockI2c, :write_read, fn ref, address, value, length ->
      assert ref() == ref
      assert 0x33 == address
      assert value == <<128, 13>>
      assert length == 2
      {:ok, <<25, 1>>}
    end)

    assert {:ok, 6401} == Control.read_control_reg1(ref())
  end

  describe "setting fps" do
    test "sets the fps" do
      ref = ref()

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

  defp ref do
    :erlang.list_to_ref(~c"#Ref<0.1.2.3>")
  end
end
