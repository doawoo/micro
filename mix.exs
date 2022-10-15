defmodule Micro.MixProject do
  use Mix.Project

  def project do
    [
      app: :micro,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Micro, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:elli, "~> 3.3"},
      {:temple, "~> 0.10.0"},
      {:file_system, "~> 0.2.10"}
    ]
  end
end
