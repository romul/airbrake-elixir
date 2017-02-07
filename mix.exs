defmodule Airbrake.Mixfile do
  use Mix.Project

  def project do
    [app: :airbrake,
     version: "0.2.4",
     elixir: "~> 1.2",
     package: package,
     description: """
       An Elixir notifier to the Airbrake
     """,
     deps: deps]
  end

  def package do
    [contributors: ["Roman Smirnov"],
     maintainers: ["Roman Smirnov"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/romul/airbrake-elixir"}]
  end

  def application do
    [applications: [:httpoison]]
  end

  defp deps do
    [{:httpoison, "~> 0.9"},
     {:poison, "~> 2.0"},
     {:ex_doc, ">= 0.0.0", only: :dev}]
  end
end
