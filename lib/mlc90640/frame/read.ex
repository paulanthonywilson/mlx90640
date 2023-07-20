defmodule Mlc90640.Frame.Read do
  @moduledoc false
  use Mlc90640.I2C
  import Bitwise

  @command_reg <<0x8000::16>>
  @frame_addr <<0x4000::16>>
  @pixel_byte_count Mlc90640.Pixels.pixel_count() * 2

  @doc """
  Is there data ready to read?
  """
  def ready?(bus, i2caddr) do
    with {:ok, <<reg::16>>} <- I2C.write_read(bus, i2caddr, @command_reg, 2) do
      {:ok, 8 == (reg &&& 8)}
    end
  end

  def next_frame(bus, i2caddr) do
    with :ok <- I2C.write(bus, i2caddr, @command_reg <> <<0x30::16>>),
         {:ok, frame} <- I2C.write_read(bus, i2caddr, @frame_addr, @pixel_byte_count),
         {:ok, ready?} <- ready?(bus, i2caddr) do
      {:ok, {frame, ready?}}
    end
  end
end
