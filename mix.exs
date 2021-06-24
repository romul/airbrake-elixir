defmodule Airbrake.Mixfile do
  use Mix.Project

  def project do
    [
      app: :airbrake,
      version: "0.6.3",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      aliases: aliases(),
      description: """
        The first Elixir notifier to the Airbrake/Errbit.
        System-wide error reporting enriched with the information from Plug and Phoenix channels.
      """,
      deps: deps(),
      docs: [main: "Airbrake"],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def package do
    [
      contributors: ["Roman Smirnov"],
      maintainers: ["Roman Smirnov"],
      licenses: ["LGPL"],
      links: %{github: "https://github.com/romul/airbrake-elixir"}
    ]
  end

  def application do
    [mod: {Airbrake, []}, applications: [:httpoison]]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:httpoison, "~> 0.9 or ~> 1.0"},
      {:mox, "~> 0.5", only: :test},
      {:poison, ">= 2.0.0", optional: true},
      {:ex_doc, "~> 0.19", only: :dev},
      {:excoveralls, "~> 0.12.0", only: :test}
    ]
  end

  defp aliases do
    [
      test: "test --no-start"
    ]
  end
end
