# Airbrake Elixir

Capture exceptions and send them to the [Airbrake](http://airbrake.io) API!

## Installation

```elixir
# Add it to your deps in your projects mix.exs
defp deps do
  [{:airbrake, "~> 0.2"}]
end

# Open up your config/config.exs (or appropriate project config)
config :airbrake, 
  api_key: "c191b51ee8c4feb0b50193c85d8d02a5",
  project_id: 112696,
  host: "http://collect.airbrake.io"
```

## Usage


Start Airbrake process manually `Airbrake.start_link`
or put `worker(Airbrake, [])` to your supervisors tree.

```elixir
# Report an exception.
try do
  :foo = :bar
rescue
  exception -> Airbrake.report(exception)
end
```
