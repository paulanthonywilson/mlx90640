# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
defmodule ExampleEeprom do
  @moduledoc false
  _doc = """
  Eeprom read from a device.
  """

  alias Mlc90640.Eeprom

  @raw_eeprom __DIR__ |> Path.join("eeprom.bin") |> File.read!()

  @expected_alphas __DIR__
                   |> Path.join("expected_alphas")
                   |> File.read!()
                   |> :erlang.binary_to_term()

  def expected_alphas, do: @expected_alphas

  def raw_eeprom, do: @raw_eeprom

  def eeprom(raw_eeprom \\ @raw_eeprom), do: Eeprom.new(raw_eeprom)

  def substitute_raw_bytes(bytes \\ @raw_eeprom, at, replace) do
    binary_part(bytes, 0, at) <>
      replace <>
      binary_part(bytes, at + byte_size(replace), byte_size(bytes) - at - byte_size(replace))
  end
end
