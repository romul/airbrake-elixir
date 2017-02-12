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

  @spec monitor(pid | {reg_name :: atom, node :: atom} | reg_name :: atom) :: {:noreply, Map.t}
  def monitor(pid_or_reg_name) do
    GenServer.cast(@name, {:monitor, pid_or_reg_name})
  end

  def start_link do
    GenServer.start_link(@name, %{}, [name: @name])
  end

  def exception_info(exception) do
    [type: inspect(exception.__struct__), message: Exception.message(exception)]
  end

  def handle_cast({:report, exception, stacktrace, options}, refs) do
    payload = Airbrake.Payload.new(exception, stacktrace, options)
    HTTPoison.post(@notify_url, Poison.encode!(payload), @request_headers)
    {:noreply, refs}
  end

  def handle_cast({:monitor, pid_or_reg_name}, refs) do
    ref = Process.monitor(pid_or_reg_name)
    refs = Map.put(refs, ref, pid_or_reg_name)
    {:noreply, refs}
  end

  def handle_info({:DOWN, ref, :process, pid, reason}, refs) do
    {pname, refs} = Map.pop(refs, ref)
    message = Enum.join([process_name(pname, pid), " is down with the reason: ", inspect(reason)])
    report(RuntimeError.exception(message))
    {:noreply, refs}
  end

  defp process_name(pid, pid), do: "Process [#{inspect(pid)}]"
  defp process_name(pname, pid), do: "#{inspect(pname)} [#{inspect(pid)}]"

end
