defmodule Airbrake.WorkerTest do
  use ExUnit.Case, async: false

  import Mox

  alias Airbrake.{HTTPMock, Payload}
  alias Airbrake.Worker.State

  setup [:set_mox_global, :verify_on_exit!]

  setup do
    worker_pid = start_worker()

    {exception, stacktrace} =
      try do
        Enum.join(3, 'million')
      rescue
        exception -> {exception, System.stacktrace()}
      end

    on_exit(&maybe_stop_worker/0)

    [exception: exception, stacktrace: stacktrace, worker_pid: worker_pid]
  end

  describe "report/1" do
    test "sends the exception and stacktrace to Airbrake", %{exception: exception, stacktrace: stacktrace} do
      expected_payload =
        exception
        |> Payload.new(stacktrace)
        |> Map.from_struct()

      caller = self()

      expect(HTTPMock, :post, fn url, payload, _headers ->
        send(caller, url: url, payload: payload)
        {:ok, %{status_code: 204}}
      end)

      Airbrake.Worker.report(exception)

      assert_receive(url: url, payload: http_payload)

      decoded_http_payload =
        http_payload
        |> Poison.decode!()
        |> atomize_keys()

      assert url =~ "/api/v3/projects/"
      assert url =~ "/notices?key="
      assert decoded_http_payload == expected_payload
      assert decoded_http_payload == expected_payload
    end
  end

  describe "remember/1" do
    setup do
      stub(Airbrake.HTTPMock, :post, fn _url, _payload, _headers ->
        {:ok, %{status_code: 204}}
      end)

      :ok
    end

    test "saves exception info in state", %{exception: exception, worker_pid: worker_pid} do
      expected_state = [type: inspect(exception.__struct__), message: Exception.message(exception)]

      Airbrake.Worker.remember(exception)

      assert %State{last_exception: {last_exception, options}} = :sys.get_state(worker_pid)
      assert last_exception == expected_state
    end
  end

  @spec atomize_keys(any()) :: map()
  defp atomize_keys(map = %{}) do
    map
    |> Enum.map(fn {k, v} -> {String.to_existing_atom(k), atomize_keys(v)} end)
    |> Enum.into(%{})
  end

  defp atomize_keys([head | rest]) do
    [atomize_keys(head) | atomize_keys(rest)]
  end

  defp atomize_keys(other), do: other

  defp start_worker do
    start_result = Airbrake.Worker.start_link()

    case start_result do
      {:ok, worker_pid} -> worker_pid
      {:error, {:already_started, worker_pid}} -> worker_pid
    end
  end

  defp maybe_stop_worker do
    pid_to_stop = GenServer.whereis(Airbrake.Worker)

    case pid_to_stop do
      nil -> :ok
      _ -> stop_worker(pid_to_stop)
    end
  end

  defp stop_worker(pid_to_stop) do
    try do
      GenServer.stop(pid_to_stop, :normal, 1_000)
    catch
      :exit, _ -> :ok
    end
  end
end
