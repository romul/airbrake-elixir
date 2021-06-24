defmodule Airbrake.LoggerBackendTest do
  use ExUnit.Case, async: false

  import Mox
  import ExUnit.CaptureLog
  require Logger

  alias Airbrake.{LoggerBackend, HTTPMock}

  setup [:set_mox_global, :verify_on_exit!]

  setup do
    Logger.add_backend({LoggerBackend, :error})
    Airbrake.start()
    :ok
  end

  describe "error handling" do
    test "sends the error via the HTTP handler" do
      caller = self()
      error_message = "** (FunctionClauseError) no function clause matching in Enum.join/2"

      expected_payload_errors =
        "\"errors\":[{\"type\":\"FunctionClauseError\",\"message\":\"no function clause matching in Enum.join/2\",\"backtrace\":[]}]"

      expect(HTTPMock, :post, fn url, payload, _headers ->
        assert payload =~ expected_payload_errors
        send(caller, url: url, payload: payload)
        {:ok, %{status_code: 204}}
      end)

      assert capture_log(fn ->
               Logger.error(error_message)
             end) =~ error_message

      assert_receive(url: _url, payload: _http_payload)
    end
  end
end
