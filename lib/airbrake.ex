defmodule Airbrake do
  @moduledoc """
  This module provides functions to report any kind of exception to
  [Airbrake](https://airbrake.io/) or [Errbit](http://errbit.com/).
  For the most common use case it allows the following workflow:

    1. Information about a web-request is collected when an exception are rescued by Airbrake.Plug and Airbrake.Channel
    2. This information is remembered and then the exception is reraised.
    3. Airbrake.LoggerBackend catches this exception again, but get another piece of information.
    4. Both pieces of information are merged and Airbrake.Worker sends it to Airbrake.

  As additional benefit, Airbrake.LoggerBackend catches not only exceptions defined with `defexception`, 
  but `exits`, `throws` and errors in background processes as well.


  ## Configuration
  The `:airbrake` application needs to be configured properly in order to
  work.

    1. Add `:airbrake` to applications list in your projects `mix.exs`
    2. Add it to your deps in `mix.exs`
    
          defp deps do
            [{:airbrake, "~> 0.5.2"}]
          end

    3. Open up your `config/config.exs` (or appropriate project config) and put the following settings in:
    
          config :airbrake,
            api_key: System.get_env("AIRBRAKE_API_KEY"),
            project_id: System.get_env("AIRBRAKE_PROJECT_ID"),
            environment: Mix.env,
            host: "https://airbrake.io", # or your Errbit host
            filter_parameters: ["password"]
          
          config :logger,
            backends: [:console, {Airbrake.LoggerBackend, :error}]


  The following is a comprehensive list of configuration options supported by Airbrake:

  **Required:**
    * `:api_key` - *required* (binary) the token needed to access the
      [Airbrake API](https://airbrake.io/docs/api/). You could find it in [User Settings](https://airbrake.io/users/edit).
    * `:project_id` - *required* (integer) the id of your project at Airbrake.

  **Optional:**
    * `:environment` - (binary or function returning binary) the environment that will
      be attached to each reported exception.
    * `:host` - (binary) use it when you have an Errbit installation.
    * `:ignore` - (MapSet of binary or function returning boolean or :all) allows to ignore some or all exceptions.
    * `:filter_parameters` - (list of binaries) allows to filter out sensitive parameters such as passwords and tokens.

  For `:api_key`, `:project_id` and `:environment` you could use a
  `{:system, "VAR_NAME"}` tuple. When given a tuple like `{:system, "VAR_NAME"}`,
  the value will be referenced from `System.get_env("VAR_NAME")` at runtime.

  ### With Phoenix

      defmodule YourApp.Router do
        use Phoenix.Router
        use Airbrake.Plug # <- put this line to your router.ex
        # ...
      end

  If you use Phoenix channels:

      def channel do
        quote do
          use Phoenix.Channel
          use Airbrake.Channel # <- put this line to your web.ex
          # ...
        end
      end
  """

  use Application

  @doc false
  @spec start(Application.app, Application.start_type) :: :ok | {:error, term}
  def start(_type \\ :normal, _args \\ []) do
    import Supervisor.Spec, warn: false

    children = [
      worker(Airbrake.Worker, [])
    ]

    opts = [strategy: :one_for_one, name: Airbrake.Supervisor]
    Supervisor.start_link(children, opts)
  end


  @spec report(Exception.t | [type: String.t, message: String.t], Keyword.t) :: :ok
  def report(exception, options \\ [])
  @doc """
  Send a report to Airbrake about given exception.

  `exception` could be Exception.t or a keywords list with two keys :type & :message

  `options` is a keywords list with following keys:
    * :params - use it to pass request params
    * :context - use it to pass detailed information about the exceptional situation
    * :session - use it to pass info about user session
    * :env - use it to pass environment variables, headers and so on
    * :stacktrace - use it when you would like send something different than System.stacktrace

  This function will always return `:ok` right away and perform the reporting of the given exception in the background.

  ## Examples
  Exceptions can be reported directly:
      Airbrake.report(ArgumentError.exception("oops"))
      #=> :ok
  Often, you'll want to report something you either rescued or caught. 

  For rescued exceptions:
      try do
        raise ArgumentError, "oops"
      rescue
        exception ->
          Airbrake.report(exception)
          # You can also reraise the exception here with reraise/2
      end
  For caught exceptions:
      try do
        throw(:oops)
        # or exit(:oops)
      catch
        kind, value ->
          Airbrake.report([type: kind, message: inspect(value)])
      end
  Using custom data:
      Airbrake.report(
        [type: "DebugInfo", message: "Something went wrong"],
        context: %{
          moon_phase: "eclipse"
        })

  """
  defdelegate report(exception, options), to: Airbrake.Worker


  @doc """
  Monitor exceptions in the target process.

  If you don't want system-wide monitoring, but would like to monitor one specific process,
  then you could use `Airbrake.monitor/1`

  Examples:

  With a given PID:
      Airbrake.monitor(pid)
  With a registered process:
      Airbrake.monitor(Registered.Process.Name)
  With `spawn/1` and its counterparts:
      spawn(fn ->
        :timer.sleep(500)
        String.upcase(nil)
      end) |> Airbrake.monitor
  """
  @spec monitor(pid | {reg_name :: atom, node :: atom} | reg_name :: atom) :: :ok
  defdelegate monitor(pid_or_reg_name), to: Airbrake.Worker
end
