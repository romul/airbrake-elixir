defmodule Airbrake.LoggerBackend do
  @moduledoc false
  @behaviour :gen_event

  def init({__MODULE__, _name}) do
    {:ok, nil}
  end

  def handle_call(_, state) do
    {:ok, :ok, state}
  end

  def handle_event({_level, gl, _event}, state)
      when node(gl) != node() do
    {:ok, state}
  end

  def handle_event({:error, _, {Logger, msg, _ts, _metadata}}, state) do
    try do
      err_info = parse_error_message(msg)
      Airbrake.report(err_info[:exception], [
        stacktrace: err_info[:stacktrace] || [],
        context: err_info[:context]
      ])
    rescue
      exception -> IO.inspect(exception)
    end
    {:ok, state}
  end
  def handle_event(_, state) do
    {:ok, state}
  end

  def handle_info(_message, state) do
    {:noreply, state}
  end

  def terminate(_reason, _state) do
    :ok
  end

  def code_change(_old, state, _extra) do
    {:ok, state}
  end

  defp parse_error_message(msg) do
    msg 
    |> to_string
    |> String.split("\n")
    |> Enum.reverse
    |> Enum.reduce(%{stacktrace: [], context: %{}}, &parse_line/2)
  end

  defp parse_line("    " <> line, res), do: parse_line(line, res)
  defp parse_line("** "  <> err_msg, res) do
    case Regex.run(~r/\((.*?)\)\s*(.*?)\z/, err_msg) do
      [_, type, message] ->
        Map.put_new(res, :exception, [type: type, message: message])
      _ ->
        Map.put_new(res, :exception, [type: "RuntimeError", message: err_msg])
    end
  end
  defp parse_line("(" <> _ = st_line, res) do
    Map.put(res, :stacktrace, [st_line | Map.get(res, :stacktrace, [])])
  end
  defp parse_line(line, res) do
    case String.split(line, ": ", parts: 2) do
      [key, value] ->
        key = key |> String.downcase |> String.to_atom
        put_in(res, [:context, key], value)
      [value] ->
        put_in(res, [:context, :title], value)
    end
  end
end
