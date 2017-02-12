# Airbrake Elixir

Capture exceptions and send them to the [Airbrake](http://airbrake.io) API!

## Installation

```elixir
# Add it to your deps in your projects mix.exs
defp deps do
  [{:airbrake, github: "romul/airbrake-elixir"}]
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


**System-wide exceptions handler**

put to `config/config.exs` or to `config/prod.exs`:

```elixir
config :logger,
  backends: [{Airbrake.LoggerBackend, :error}]
```


**With Phoenix:**

```elixir
defmodule YourApp.Router do
  use Phoenix.Router
  use Airbrake.Plug

  # ...
end
```

in `web/web.ex`:
```elixir
  def channel do
    quote do
      use Phoenix.Channel
      use Airbrake.Channel
      # ...
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


**Custom usage example:**

```elixir
# Report an exception.
try do
  String.upcase(nil)
rescue
  exception -> Airbrake.report(exception)
end
```

