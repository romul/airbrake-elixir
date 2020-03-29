defmodule AirbrakeTest do
  use ExUnit.Case, async: false

  import Mox

  setup [:set_mox_global, :verify_on_exit!]

  setup do
    stub(Airbrake.HTTPMock, :post, fn _url, _payload, _headers ->
      {:ok, %{status_code: 204}}
    end)

    Airbrake.start()
    :ok
  end

  test "it doesn't raise errors if you send invalid arguments to Airbrake.report/2" do
    Airbrake.report(Enum, %{ignore: :this_error_in_test})
  end

  test "it doesn't raise errors if you send invalid arguments to Airbrake.Worker.remember/2" do
    Airbrake.Worker.remember(Enum, %{ignore: :this_error_in_test})
  end

  test "it handles real errors" do
    try do
      Airbrake.undefined_method()
    rescue
      exception -> Airbrake.report(exception)
    end
  end
end
