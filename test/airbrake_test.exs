defmodule AirbrakeTest do
  use ExUnit.Case

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
