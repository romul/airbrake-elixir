defmodule Airbrake.Mixfile do
  use Mix.Project

  def project do
    [app: :airbrake,
     version: "0.1.0",
     elixir: "~> 1.0.0",
     package: package,
     description: """
       An Elixir notifier to the Airbrake
     """,
     deps: deps]
  end

  def package do
    [contributors: ["Roman Smirnov"],
     licenses: ["MIT"],
     links: %{github: "https://github.com/romul/airbrake-elixir"}]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [{:httpoison, "~> 0.6"},
     {:poison, "~> 1.3"}]
  end
end
