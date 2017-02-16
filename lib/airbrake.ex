defmodule Airbrake do
  use Application

  @doc """
  Application callback to start Airbrake worker.
  """
  @spec start(Application.app, Application.start_type) :: :ok | {:error, term}
  def start(_type \\ :normal, _args \\ []) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Airbrake.Worker, [])
    ]

    opts = [strategy: :one_for_one, name: Airbrake.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Send a report to Airbrake.
  """
  defdelegate report(exception, options \\ []), to: Airbrake.Worker

  defdelegate remember(exception, options \\ []), to: Airbrake.Worker

  @doc """
  Monitor exceptions in the target process.
  """
  defdelegate monitor(pid_or_reg_name), to: Airbrake.Worker
end
