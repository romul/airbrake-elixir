defmodule Airbrake.GenServer do
  @moduledoc """
  This module provides the ability to monitor workers of your gen.servers,
  just write `use Airbrake.GenServer` instead of `use GenServer`
  and any time when GenServer would be terminated for a some reason you will know about it.

  Could be used in case when you don't want a system-wide reporting.
  """

  defmacro __using__(_opts) do
    quote do
      use GenServer
      import Airbrake.GenServer
    end
  end

  @doc """
  Implements [`terminate/2`](https://hexdocs.pm/elixir/1.4.1/GenServer.html#c:terminate/2) callback. It just calls `handle_terminate/1` and could be overridden.
  """
  def terminate(reason, _state) do
    handle_terminate(reason)
    :ok
  end

  @doc """
  Implements a set of reporting rules. Could be overridden if you want to.
  """
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