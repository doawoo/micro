defmodule Micro.MixProject do
  use Mix.Project

  def project do
    [
      app: :micro,
      releases: releases(),
      compilers: [:temple] ++ Mix.compilers(),
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
      {:file_system, "~> 0.2.10"},
      {:jason, "~> 1.4"},
      {:mime, "~> 2.0"},
      {:burrito, git: "https://github.com/burrito-elixir/burrito"}
    ]
  end

  def releases do
    [
      micro: [
        steps: [:assemble, &Burrito.wrap/1],
        burrito: [
          targets: [
            macos: [os: :darwin, cpu: :x86_64],
            macos_m1: [os: :darwin, cpu: :aarch64],
            linux: [os: :linux, cpu: :x86_64],
            linux_musl: [os: :linux, cpu: :x86_64, libc: :musl],
          ],
          debug: Mix.env() != :prod
        ]
      ]
    ]
  end
end
