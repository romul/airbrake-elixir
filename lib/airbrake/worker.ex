defmodule Airbrake.Worker do
  use GenServer

  defmodule State do
    defstruct refs: %{}, last_exception: nil
  end

  @name __MODULE__
  @request_headers [{"Content-Type", "application/json"}]
  @project_id Application.get_env(:airbrake, :project_id)
  @api_key Application.get_env(:airbrake, :api_key)
  @host Application.get_env(:airbrake, :host, "http://collect.airbrake.io")
  @notify_url "#{@host}/api/v3/projects/#{@project_id}/notices?key=#{@api_key}"


  @doc """
  Send a report to Airbrake.
  """
  @spec report(Exception.t | [type: String.t, message: String.t], Keyword.t) :: :ok
  def report(exception, options \\ [])
  def report(%{__exception__: true} = exception, options) when is_list(options) do
    report(exception_info(exception), options)
  end
  def report([type: _, message: _] = exception, options) when is_list(options) do
    stacktrace = options[:stacktrace] || System.stacktrace
    GenServer.cast(@name, {:report, exception, stacktrace, Keyword.delete(options, :stacktrace)})
  end
  def report(_, _) do
    {:error, ArgumentError}
  end


  @spec report(Exception.t | [type: String.t, message: String.t], Keyword.t) :: :ok
  def remember(exception, options \\ [])
  def remember(%{__exception__: true} = exception, options) when is_list(options) do
    remember(exception_info(exception), options)
  end
  def remember([type: _, message: _] = exception, options) when is_list(options) do
    GenServer.cast(@name, {:remember, exception, options})
  end

  @spec monitor(pid | {reg_name :: atom, node :: atom} | reg_name :: atom) :: {:noreply, Map.t}
  def monitor(pid_or_reg_name) do
    GenServer.cast(@name, {:monitor, pid_or_reg_name})
  end

  def start_link do
    GenServer.start_link(@name, %State{}, [name: @name])
  end

  def exception_info(exception) do
    [type: inspect(exception.__struct__), message: Exception.message(exception)]
  end

  def handle_cast({:report, exception, stacktrace, options}, %{last_exception: {exception, details}} = state) do
    enhanced_options = Enum.reduce([:context, :params, :session], options, fn(key, enhanced_options) ->
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
    state = put_in(state, [:refs, ref], pid_or_reg_name)
    {:noreply, state}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, state) do
    {pname, refs} = Map.pop(state.refs, ref)
    message = Enum.join([process_name(pname, pid), " is down with the reason: ", inspect(reason)])
    report(RuntimeError.exception(message))
    {:noreply, Map.put(state, :refs, refs)}
  end

  defp send_report(exception, stacktrace, options) do
    unless ignore?(exception) do
      payload = Airbrake.Payload.new(exception, stacktrace, options)
      HTTPoison.post(@notify_url, Poison.encode!(payload), @request_headers)
    end
  end

  defp ignore?([type: type, message: message]) do
    ignore?(Application.get_env(:airbrake, :ignore), type, message)
  end
  defp ignore?(nil, _type, _message), do: false
  defp ignore?(:all, _type, _message), do: true
  defp ignore?(%MapSet{} = types, type, _message), do: MapSet.member?(types, type)
  defp ignore?(fun, type, message) when is_function(fun), do: fun.(type, message)


  defp process_name(pid, pid), do: "Process [#{inspect(pid)}]"
  defp process_name(pname, pid), do: "#{inspect(pname)} [#{inspect(pid)}]"

end
