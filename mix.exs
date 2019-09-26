defmodule Airbrake.Mixfile do
  use Mix.Project

  def project do
    [
      app: :airbrake,
      version: "0.6.2",
      elixir: "~> 1.7",
      package: package(),
      description: """
        The first Elixir notifier to the Airbrake/Errbit.
        System-wide error reporting enriched with the information from Plug and Phoenix channels.
      """,
      deps: deps(),
      docs: [main: "Airbrake"]
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

  defp deps do
    [
      {:httpoison, "~> 0.9 or ~> 1.0"},
      {:poison, ">= 2.0.0", optional: true},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end
end
