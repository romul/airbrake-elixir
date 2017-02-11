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
            stacktrace = System.stacktrace

            Airbrake.report(exception, [
              params: conn.params,
              session: conn.private[:plug_session],
              stacktrace: stacktrace
            ])

            reraise exception, stacktrace
        end
      end

    end
  end
end