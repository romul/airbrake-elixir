defmodule Airbrake.Worker do
  @moduledoc false
  use GenServer

  defmodule State do
    @moduledoc false
    defstruct refs: %{}, last_exception: nil
  end

  @name __MODULE__
  @request_headers [{"Content-Type", "application/json"}]
  @default_host "https://airbrake.io"

  @doc """
  Send a report to Airbrake.
  """
  @spec report(Exception.t() | [type: String.t(), message: String.t()], Keyword.t()) :: :ok
  def report(exception, options \\ [])

  def report(%{__exception__: true} = exception, options) when is_list(options) do
    report(exception_info(exception), options)
  end

  def report([type: _, message: _] = exception, options) when is_list(options) do
    stacktrace = options[:stacktrace] || System.stacktrace()
    GenServer.cast(@name, {:report, exception, stacktrace, Keyword.delete(options, :stacktrace)})
  end

  def report(_, _) do
    {:error, ArgumentError}
  end

  @spec remember(Exception.t() | [type: String.t(), message: String.t()], Keyword.t()) :: :ok
  def remember(exception, options \\ [])

  def remember(%{__exception__: true} = exception, options) when is_list(options) do
    remember(exception_info(exception), options)
  end

  def remember([type: _, message: _] = exception, options) when is_list(options) do
    GenServer.cast(@name, {:remember, exception, options})
  end

  def monitor(pid_or_reg_name) do
    GenServer.cast(@name, {:monitor, pid_or_reg_name})
  end

  def start_link do
    GenServer.start_link(@name, %State{}, name: @name)
  end

  def exception_info(exception) do
    [type: inspect(exception.__struct__), message: Exception.message(exception)]
  end

  def init(state), do: {:ok, state}

  def handle_cast({:report, exception, stacktrace, options}, %{last_exception: {exception, details}} = state) do
    enhanced_options =
      Enum.reduce([:context, :params, :session, :env], options, fn key, enhanced_options ->
        Keyword.put(enhanced_options, key, Map.merge(options[key] || %{}, details[key] || %{}))
      end)

    send_report(exception, stacktrace, enhanced_options)
    {:noreply, Map.put(state, :last_exception, nil)}
  end

  def handle_cast({:report, exception, stacktrace, options}, state) do
    send_report(exception, stacktrace, options)
    {:noreply, state}
  end

  def handle_cast({:remember, exception, options}, state) do
    state = Map.put(state, :last_exception, {exception, options})
    {:noreply, state}
  end

  def handle_cast({:monitor, pid_or_reg_name}, state) do
    ref = Process.monitor(pid_or_reg_name)
    state = Map.put(state, :refs, Map.put(state.refs, ref, pid_or_reg_name))
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    {pname, refs} = Map.pop(state.refs, ref)
    Airbrake.GenServer.handle_terminate(reason, %{process_name: process_name(pname, pid)})
    {:noreply, Map.put(state, :refs, refs)}
  end

  defp send_report(exception, stacktrace, options) do
    unless ignore?(exception) do
      enhanced_options = build_options(options)
      payload = Airbrake.Payload.new(exception, stacktrace, enhanced_options)
      json_encoder = Application.get_env(:airbrake, :json_encoder, Poison)
      HTTPoison.post(notify_url(), json_encoder.encode!(payload), @request_headers)
    end
  end

  defp build_options(current_options) do
    case get_env(:options) do
      {mod, fun, 1} ->
        apply(mod, fun, [current_options])

      shared_options when is_list(shared_options) ->
        Keyword.merge(shared_options, current_options)

      _ ->
        current_options
    end
  end

  defp ignore?(type: type, message: message) do
    ignore?(get_env(:ignore), type, message)
  end

  defp ignore?(nil, _type, _message), do: false
  defp ignore?(:all, _type, _message), do: true
  defp ignore?(%MapSet{} = types, type, _message), do: MapSet.member?(types, type)
  defp ignore?(fun, type, message) when is_function(fun), do: fun.(type, message)

  defp process_name(pid, pid), do: "Process [#{inspect(pid)}]"
  defp process_name(pname, pid), do: "#{inspect(pname)} [#{inspect(pid)}]"

  defp notify_url do
    "#{get_env(:host, @default_host)}/api/v3/projects/#{get_env(:project_id)}/notices?key=#{get_env(:api_key)}"
  end

  def get_env(key, default \\ nil) do
    :airbrake
    |> Application.get_env(key, default)
    |> process_env()
  end

  defp process_env({:system, key, default}), do: System.get_env(key) || default
  defp process_env({:system, key}), do: System.get_env(key)
  defp process_env(value), do: value
end
