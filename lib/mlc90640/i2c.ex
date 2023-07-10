defmodule Mlc90640.I2C do
  @moduledoc false

  @i2c_impl if Mix.env() == :test && Mix.target() != :elixir_ls, do: MockI2c, else: Circuits.I2C

  defmacro __using__(_) do
    quote do
      alias unquote(@i2c_impl), as: I2C
    end
  end
end
