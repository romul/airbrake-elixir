defmodule Airbrake do
  use GenServer

  @name __MODULE__
  @request_headers [{"Content-Type", "application/json"}]
  @project_id Application.get_env(:airbrake, :project_id)
  @api_key Application.get_env(:airbrake, :api_key)
  @host Application.get_env(:airbrake, :host, "http://collect.airbrake.io")
  @notify_url "#{@host}/api/v3/projects/#{@project_id}/notices?key=#{@api_key}"
  
  @doc """
  Send a report to Airbrake.
  """
  def report(exception, options \\ [])
  def report(%{__exception__: true} = exception, options) when is_list(options) do
    stacktrace = System.stacktrace
    GenServer.cast(@name, {:report, exception, stacktrace, options})
  end
  def report(_, _) do
    {:error, ArgumentError}
  end

  def start_link do
    HTTPoison.start
    GenServer.start_link(@name, nil, [name: @name])
  end

  def handle_cast({:report, exception, stacktrace, options}, state) do
    payload = Airbrake.Payload.new(exception, stacktrace, options)
    HTTPoison.post(@notify_url, Poison.encode!(payload), @request_headers)
    {:noreply, state}
  end

end
