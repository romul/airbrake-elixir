# Airbrake Elixir

Capture exceptions and send them to the [Airbrake](http://airbrake.com) API!

## Installation

```elixir
# Add it to your deps in your projects mix.exs
defp deps do
  [{:airbrake, "~> 0.1.0"}]
end

# Open up your config/config.exs (or appropriate project config)
config :airbrake, 
  api_key: "c191b51ee8c4feb0b50193c85d8d02a5",
  project_id: 112696
```

## Usage

```elixir
# Turn the lights on.
Airbrake.start

# Report an exception.
try do
  :foo = :bar
rescue
  exception -> Airbrake.report(exception)
end
```
