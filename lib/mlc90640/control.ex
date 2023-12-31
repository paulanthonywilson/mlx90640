defmodule Mlc90640.Control do
  @moduledoc false
  _doc = """
  Controls the device via i2c
  """

  use Mlc90640.I2C

  alias Mlc90640.{Bytey, Commands}
  alias Mlc90640.Eeprom

  @bus_name "i2c-1"
  @mlc90640_addr 0x33

  @control_reg1_bytes Bytey.to_unsigned_2_bytes(0x800D)

  @eeprom_addr 0x2400
  @eeprom_last_eeprom_addr 0x273F
  @eeprom_start Bytey.to_unsigned_2_bytes(@eeprom_addr)
  @eeprom_byte_size (@eeprom_last_eeprom_addr - @eeprom_addr + 1) * 2

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
    with {:ok, <<h, l>>} <- I2C.write_read(bus, @mlc90640_addr, @control_reg1_bytes, 2) do
      {:ok, h * 256 + l}
    end
  end

  @doc """
  Set the Frames per second (frequency), also ensuring that chessboard pattern is set.
  """
  @spec set_chessboard_and_fps(reference, number) :: :ok | {:error, any}
  def set_chessboard_and_fps(bus, fps) do
    with {:ok, value} <- read_control_reg1(bus) do
      new_value_bytes =
        value
        |> Commands.control_reg1_with_fps(fps)
        |> Bytey.to_unsigned_2_bytes()

      I2C.write(bus, @mlc90640_addr, @control_reg1_bytes <> new_value_bytes)
    end
  end

  @doc """
  Read and extract the EEPROM parameters
  """
  @spec read_eeprom(reference) :: {:ok, Mlc90640.Eeprom.Params.t()}
  def read_eeprom(bus) do
    with {:ok, eeprom} <- I2C.write_read(bus, @mlc90640_addr, @eeprom_start, @eeprom_byte_size) do
      {:ok, Eeprom.extract_parameters(eeprom)}
    end
  end

  def stop(bus) do
    I2C.close(bus)
  end
end
