# Airbrake Elixir

[![Build Status](https://travis-ci.org/romul/airbrake-elixir.svg?branch=master)](https://travis-ci.org/romul/airbrake-elixir)
[![Hex Version](https://img.shields.io/hexpm/v/airbrake.svg "Hex Version")](https://hex.pm/packages/airbrake)

Capture exceptions and send them to the [Airbrake](http://airbrake.io) or to your Errbit installation!

## Installation

```elixir
# 1. Add :airbrake to applications list in your projects mix.exs

# 2. Add it to your deps in your projects mix.exs
defp deps do
  [
    {:airbrake, "~> 0.6"},
    {:httpoison, "~> 1.0"} # if you use Elixir 1.8+
  ]
end

# 3. Open up your config/config.exs (or appropriate project config)
config :airbrake,
  api_key: System.get_env("AIRBRAKE_API_KEY"),
  project_id: System.get_env("AIRBRAKE_PROJECT_ID"),
  environment: Mix.env,
  host: "https://airbrake.io" # or your Errbit host

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

## Shared options for reporting data to Airbrake

To include with every report to Airbrake a set of optional data, include the `:options` key in the config. This can either
be a keyword list of options or a function that returns a keyword list of options. Keyword list keys that can be used are
`:context`, `:params`, `:session`, and `:env`.

### Options function in config

A function for creating options for reporting should be declared in the config as a tuple of 
`{ModuleName, :function_name, 1}`. This function should take as an argument a keyword list, possibly empty and should
return a keyword list. The function arity is always 1.

```elixir
config :airbrake,
  options: {Web, :airbrake_options, 1}
```

### Options keyword list in config

When options are provided as a keyword list in the configuration and a specific call to `Airbrake.report/2` includes 
options in its parameters, the options will be merged, with the parameters taking precedence.

```elixir
config :airbrake,
  options: [env: %{"SOME_ENVIRONMENT_VARIABLE" => "environment variable"}]
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




