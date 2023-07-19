defmodule Mlc90640.Eeprom do
  @moduledoc false

  alias Mlc90640.Eeprom.{Params, ParamsExtraction, Partitioned}

  @doc """
  Takes the Eeprom values and converts to parameters
  """
  @spec extract_parameters(binary()) :: Params.t()
  def extract_parameters(eeprom_binary) do
    eeprom = Partitioned.new(eeprom_binary)

    %Params{}
    |> ParamsExtraction.vdd(eeprom)
    |> ParamsExtraction.ptat(eeprom)
    |> ParamsExtraction.gain(eeprom)
    |> ParamsExtraction.tgc(eeprom)
    |> ParamsExtraction.resolution(eeprom)
    |> ParamsExtraction.ksta(eeprom)
    |> ParamsExtraction.ksto(eeprom)
    |> ParamsExtraction.cp(eeprom)
    |> ParamsExtraction.alpha(eeprom)
    |> ParamsExtraction.offsets(eeprom)
    |> ParamsExtraction.kta_pixels(eeprom)
    |> ParamsExtraction.kv_pixels(eeprom)
    |> ParamsExtraction.cilc(eeprom)
    |> ParamsExtraction.kv_pixels(eeprom)
    |> ParamsExtraction.kta_pixels(eeprom)
    |> ParamsExtraction.deviants(eeprom)
  end
end
