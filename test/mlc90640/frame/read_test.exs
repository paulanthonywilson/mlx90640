defmodule Mlc90640.Frame.ReadTest do
  use I2cCase
  alias Mlc90640.Frame.Read
  import Mox

  describe "data_ready?" do
    test "returns false if the data is not ready", %{ref: ref} do
      expect(MockI2c, :write_read, fn ^ref, 0x33, <<128, 0>>, 2 ->
        {:ok, <<0::16>>}
      end)

      assert {:ok, false} = Read.ready?(ref, 0x33)
    end

    test "returns true if read", %{ref: ref} do
      expect(MockI2c, :write_read, fn ^ref, 0x33, <<128, 0>>, 2 ->
        {:ok, <<8::16>>}
      end)

      assert {:ok, true} = Read.ready?(ref, 0x33)
    end

    test "returns read error" do
      stub(MockI2c, :write_read, fn _, _, _, _ ->
        {:error, "nope"}
      end)

      assert {:error, "nope"} = Read.ready?(ref(), 0x33)
    end
  end

  describe "read frame" do
    test "without error", %{ref: ref} do
      expect(MockI2c, :write, fn ^ref, 0x33, <<0x8000::16, 0x30::16>> ->
        :ok
      end)

      expect(MockI2c, :write_read, fn ^ref, 0x33, <<0x4000::16>>, 1_536 ->
        {:ok, <<0xFA::1536>>}
      end)

      expect(MockI2c, :write_read, fn ^ref, 0x33, <<0x8000::16>>, 2 ->
        {:ok, <<0::16>>}
      end)

      assert {:ok, {<<0xFA::1536>>, false}} == Read.next_frame(ref, 0x33)
    end

    test "without error but still ready after reading" do
      stub(MockI2c, :write, fn _, _, <<0x8000::16, 0x30::16>> ->
        :ok
      end)

      stub(MockI2c, :write_read, fn
        _, _, <<0x4000::16>>, _ ->
          {:ok, <<0xFA::1536>>}

        _, _, <<0x8000::16>>, _ ->
          {:ok, <<8::16>>}
      end)

      assert {:ok, {<<0xFA::1536>>, true}} == Read.next_frame(ref(), 0x33)
    end

    test "error on initialisation" do
      expect(MockI2c, :write, fn _, 0x33, <<0x8000::16, 0x30::16>> ->
        {:error, "nope"}
      end)

      expect(MockI2c, :write_read, 0, fn _, _, _, _ ->
        {:ok, <<0xFA::1536>>}
      end)

      assert {:error, "nope"} = Read.next_frame(ref(), 0x33)
    end

    test "error on read frame" do
      expect(MockI2c, :write, fn _, _, _ ->
        :ok
      end)

      expect(MockI2c, :write_read, fn _, _, <<0x4000::16>>, _ ->
        {:error, "nope"}
      end)

      assert {:error, "nope"} = Read.next_frame(ref(), 0x33)
    end

    test "error on recheck if data ready" do
      expect(MockI2c, :write, fn _, _, _ ->
        :ok
      end)

      expect(MockI2c, :write_read, fn _, _, <<0x4000::16>>, _ ->
        {:ok, <<0xFA::1536>>}
      end)

      expect(MockI2c, :write_read, fn _, _, <<0x8000::16>>, _ ->
        {:error, "nope"}
      end)

      assert {:error, "nope"} = Read.next_frame(ref(), 0x33)
    end
  end
end
