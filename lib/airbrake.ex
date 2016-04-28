defmodule Airbrake do
  @request_headers [{"Content-Type", "application/json"}]

  alias Airbrake.Payload
  use HTTPoison.Base

  def report(exception, options \\ []) do
    stacktrace = System.stacktrace
    spawn fn ->
      post(notify_url,
           Payload.new(exception, stacktrace, options) |> to_json,
           @request_headers)
    end
  end

  def to_json(payload) do
    Poison.encode!(payload)
  end

  defp notify_url do
    project_id = Application.get_env(:airbrake, :project_id)
    api_key = Application.get_env(:airbrake, :api_key)
    host = Application.get_env(:airbrake, :host)
    "#{host}/api/v3/projects/#{project_id}/notices?key=#{api_key}"
  end
end
