defmodule Airbrake.Plug do
  defmacro __using__(_env) do
    quote location: :keep do
      @before_compile Airbrake.Plug
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      defoverridable [call: 2]

      def call(conn, opts) do
        try do
          super(conn, opts)
        rescue
          exception ->
            send_to_airbrake(conn, exception)
        end
      end

      defp send_to_airbrake(conn, exception) do
        stacktrace = System.stacktrace
        error = case exception do
          %Plug.Conn.WrapperError{} ->
            case Regex.run(~r/\*\*\s*\((.*?)\)\s*(.*?)\z/, Exception.message(exception)) do
              [_, type, message] ->
                [type: type, message: message]
              _ ->
                exception
            end
        end
        Airbrake.report(error, [
          params: conn.params,
          session: conn.private[:plug_session],
          stacktrace: stacktrace
        ])
        reraise exception, stacktrace
      end

    end
  end
end