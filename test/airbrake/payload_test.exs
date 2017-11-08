defmodule Airbrake.PayloadTest do
  use ExUnit.Case
  alias Airbrake.Payload

  def get_problem do
    try do
      # If the following line is not on line 9 then tests will start failing.
      # You've been warned!
      Harbour.cats(3)
    rescue
      exception -> [exception, System.stacktrace]
    end
  end

  def get_payload(options \\ []) do
    apply Payload, :new, List.insert_at(get_problem(), -1, options)
  end

  def get_error(options \\ []) do
    %{errors: [error]} = get_payload(options)
    error
  end

  def get_context(options \\ []) do
    %{context: context} = get_payload(options)
    context
  end

  test "it adds the context when given" do
    %{context: context} = get_payload([context: %{msg: "Potato#cake"}])
    assert "Potato#cake" == context.msg
  end


  test "it generates correct stacktraces" do
    {exception, stacktrace} = try do
      Enum.join(3, 'million')
    rescue
      exception -> {exception, System.stacktrace}
    end
    %{errors: [%{backtrace: stacktrace}]} = Payload.new(exception, stacktrace, [])
    assert [%{file: "lib/enum.ex", line: _, function: _},
            %{file: "test/airbrake/payload_test.exs", line: _, function: "Elixir.Airbrake.PayloadTest.test it generates correct stacktraces/1"}
            | _] = stacktrace
  end

  test "it generates correct stacktraces when the current file was a script" do
    assert [%{file: "unknown", line: 0, function: _},
            %{file: "test/airbrake/payload_test.exs", line: 9, function: "Elixir.Airbrake.PayloadTest.get_problem/0"},
            %{file: "test/airbrake/payload_test.exs", line: _, function: _} | _] = get_error().backtrace
  end

  # NOTE: Regression test
  test "it generates correct stacktraces when the method arguments are in place of arity" do
    {exception, stacktrace} = try do
      Fart.poo(:butts, 1, "foo\n")
    rescue
      exception -> {exception, System.stacktrace}
    end
    %{errors: [%{backtrace: stacktrace}]} = Payload.new(exception, stacktrace, [])
    assert [%{file: "unknown", line: 0, function: "Elixir.Fart.poo(:butts, 1, \"foo\\n\")"},
            %{file: "test/airbrake/payload_test.exs", line: _, function: _} | _] = stacktrace
  end

  test "it reports the error class" do
    assert "UndefinedFunctionError" == get_error().type
  end

  test "it reports the error message" do
    assert "function Harbour.cats/1 is undefined (module Harbour is not available)" == get_error().message
  end

  test "it reports the notifier" do
    assert %{name: "Airbrake Elixir",
             url: "https://github.com/romul/airbrake-elixir",
             version: _} = get_payload().notifier
  end
end
