defmodule AirbrakeTest do
  use ExUnit.Case

  test "it doesn't raise errors if you report garbage" do
    Airbrake.report(Enum, %{ignore: :this_error_in_test})
  end

  test "it handles real errors" do
    try do
      Airbrake.undefined_method()
    rescue
      exception -> Airbrake.report(exception)
    end
  end

  test "it can encode json" do
    assert Airbrake.to_json(%{foo: 3, bar: "baz"}) ==
      "{\"foo\":3,\"bar\":\"baz\"}"
  end
end
