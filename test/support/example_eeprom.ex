# credo:disable-for-this-file Credo.Check.Readability.LargeNumbers
defmodule ExampleEeprom do
  @moduledoc false
  _doc = """
  Eeprom read from a device.
  """

  alias Mlc90640.Eeprom

  read_expected = fn file_name ->
    __DIR__
    |> Path.join(file_name)
    |> File.read!()
    |> :erlang.binary_to_term()
  end

  @raw_eeprom __DIR__ |> Path.join("eeprom.bin") |> File.read!()

  @expected_alphas read_expected.("expected_alphas")
  @expected_offsets read_expected.("expected_offsets")
  @expected_ktas read_expected.("expected_ktas")
  @ktas_with_negative_rc_0 read_expected.("ktas_with_negative_rc0")
  @expected_kvs read_expected.("expected_kvs")
  @kvs_with_negative_rc_0 read_expected.("kvs_with_negative_rc0")

  def expected_ktas, do: @expected_ktas

  def expected_alphas, do: @expected_alphas
  def expected_offsets, do: @expected_offsets
  def expected_kvs, do: @expected_kvs

  @doc """
  Also from the library, injecting in a negative value to kta rc_0
  (row odd, column odd)
  """
  def ktas_with_negative_rc_0, do: @ktas_with_negative_rc_0

  @doc """
  Also from the library, injecting in a negative value to kta rc_0
  (row odd, column odd)
  """
  def kvs_with_negative_rc_0, do: @kvs_with_negative_rc_0

  def raw_eeprom, do: @raw_eeprom

  def eeprom(raw_eeprom \\ @raw_eeprom), do: Eeprom.new(raw_eeprom)

  def substitute_raw_bytes(bytes \\ @raw_eeprom, at, replace) do
    binary_part(bytes, 0, at) <>
      replace <>
      binary_part(bytes, at + byte_size(replace), byte_size(bytes) - at - byte_size(replace))
  end
end
