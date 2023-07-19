defmodule Mlc90640.EepromTest do
  use ExUnit.Case
  alias Mlc90640.Eeprom
  alias Mlc90640.Eeprom.Params

  test "populates all the parameters" do
    assert %Params{} = params = Eeprom.extract_parameters(ExampleEeprom.raw_eeprom())

    assert [] =
             params
             |> Map.from_struct()
             |> Map.values()
             |> Enum.filter(&is_nil/1)
  end
end
