use Mix.Config

config :airbrake,
  private: [http_adapter: Airbrake.HTTPMock]
