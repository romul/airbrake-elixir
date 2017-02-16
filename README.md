# Airbrake Elixir

Capture exceptions and send them to the [Airbrake](http://airbrake.io) or to your Errbit installation!

## Installation

```elixir
# 1. Add :airbrake to applications list in your projects mix.exs

# 2. Add it to your deps in your projects mix.exs
defp deps do
  [{:airbrake, github: "romul/airbrake-elixir"}]
end

# 3. Open up your config/config.exs (or appropriate project config)
config :airbrake,
  api_key: System.get_env("AIRBRAKE_API_KEY"),
  project_id: System.get_env("AIRBRAKE_PROJECT_ID"),
  environment: Mix.env,
  host: "http://collect.airbrake.io" # or your Errbit host

config :logger,
  backends: [{Airbrake.LoggerBackend, :error}, :console]
```

## General usage

**With Phoenix:**

```elixir
defmodule YourApp.Router do
  use Phoenix.Router
  use Airbrake.Plug # <- put this line to your router.ex

  # ...
end
```

```elixir
  def channel do
    quote do
      use Phoenix.Channel
      use Airbrake.Channel # <- put this line to your web.ex
      # ...
```


## Ignore some exceptions

To ignore some exceptions use `:ignore` key in config:

```elixir
config :airbrake,
  ignore: MapSet.new(["Custom.Error"])

# or

config :airbrake,
  ignore: fn(type, message) ->
    type == "Custom.Error" && String.contains?(message, "silent error")
  end

# or

config :airbrake,
  ignore: :all # to disable reporting
```


## Custom usage examples

```elixir
# Report an exception.
try do
  String.upcase(nil)
rescue
  exception -> Airbrake.report(exception)
end
```

**With GenServer:**

```elixir
defmodule MyServer do
  # use Airbrake.GenServer instead of GenServer
  use Airbrake.GenServer
  # ...
end
```

**With any process:**

```elixir
  Airbrake.monitor(pid)
  # or
  Airbrake.monitor(Registered.Process.Name)
  # or with spawn
  spawn(fn -> 
    :timer.sleep(500)
    String.upcase(nil)
  end) |> Airbrake.monitor
```




