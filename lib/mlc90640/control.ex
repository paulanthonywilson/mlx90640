defmodule Mlc90640.Control do
  @moduledoc false
  _doc = """
  Controls the device via i2c
  """

  use Mlc90640.I2C

  alias Mlc90640.{Bytey, Commands}

  @bus_name "i2c-1"
  @mlc90640_addr 0x33

  @control_reg1 0x800D
  @control_reg1_bytes Bytey.to_unsigned_2_bytes(@control_reg1)

  @type i2c_bus :: Circuits.I2C.bus()

  @doc """
  Start the I2C bus. Returns the ref in an `:ok` tuple.
  """
  @spec start :: {:error, any} | {:ok, i2c_bus()}
  def start do
    I2C.open(@bus_name)
  end

  @doc """
  Get the value of the control reg - an unsigned 16 bit integer
  """
  @spec read_control_reg1(i2c_bus()) :: {:ok, non_neg_integer}
  def read_control_reg1(bus) do
    case I2C.write_read(bus, @mlc90640_addr, @control_reg1_bytes, 2) do
      {:ok, <<h, l>>} -> {:ok, h * 256 + l}
    end
  end

  def set_chessboard_and_fps(bus, fps) do
    with {:ok, value} <- read_control_reg1(bus) do
      new_value_bytes =
        value
        |> Commands.control_reg1_with_fps(fps)
        |> Bytey.to_unsigned_2_bytes()

      I2C.write(bus, @mlc90640_addr, @control_reg1_bytes <> new_value_bytes)
    end
  end

  def stop(bus) do
    I2C.close(bus)
  end
end
