defmodule Mlx90640.MixProject do
  use Mix.Project

  def project do
    [
      app: :mlx90640,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:circuits_i2c,
       git: "git@github.com:paulanthonywilson/circuits_i2c.git", branch: "with-behaviour"},
      # {:circuits_i2c, path: "../circuits_i2c"},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:dialyxir, "~> 1.3", runtime: false, only: [:dev, :test]},
      {:mox, "~> 1.0", only: :test}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
