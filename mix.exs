# SPDX-FileCopyrightText: 2025 Erlang Ecosystem Foundation
# SPDX-License-Identifier: Apache-2.0

defmodule OpenSSFCompliance.MixProject do
  use Mix.Project

  def project do
    [
      app: :openssf_compliance,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {OpenSSFCompliance.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:explorer, "~> 0.11.0"},
      {:hex_core, "~> 0.11.0"},
      {:req, "~> 0.5.8"},
      {:styler, "~> 1.2", only: [:dev, :test], runtime: false}
    ]
  end
end
