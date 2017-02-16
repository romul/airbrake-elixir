defmodule Airbrake.Plug do
  defmacro __using__(_env) do
    quote location: :keep do
      use Plug.ErrorHandler

      defp handle_errors(conn, %{kind: _level, reason: exception, stack: stacktrace}) do
        conn = conn |> Plug.Conn.fetch_cookies |> Plug.Conn.fetch_query_params
        headers = Enum.into(conn.req_headers, %{})

        conn_data = %{
          url: "#{conn.scheme}://#{conn.host}:#{conn.port}#{conn.request_path}",
          userIP: (conn.remote_ip |> Tuple.to_list() |> Enum.join(".")),
          userAgent: headers["user-agent"],
          cookies: conn.req_cookies
        }
        environment = %{
          headers: headers,
          httpMethod: conn.method
        }

        Airbrake.remember(exception, [
          params: conn.params,
          session: conn.private[:plug_session],
          context: conn_data,
          environment: environment,
          stacktrace: stacktrace
        ])
      end
    end
  end
end