defmodule Airbrake.GenServer do
  defmacro __using__(_opts) do
    quote do
      use GenServer
      import Airbrake.GenServer
    end
  end

  def terminate(reason, _state) do
    handle_terminate(reason)
    :ok
  end

  def handle_terminate(:normal), do: nil
  def handle_terminate(:shutdown), do: nil
  def handle_terminate({:shutdown, _}), do: nil
  def handle_terminate({err_type, stacktrace}) when is_atom(err_type) and is_list(stacktrace) do
    ErlangError.normalize(err_type, stacktrace) |> Airbrake.report
  end
  def handle_terminate(reason) do
    RuntimeError.exception(inspect(reason)) |> Airbrake.report
  end

  defoverridable [terminate: 2, handle_terminate: 1]
end