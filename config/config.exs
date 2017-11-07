use Mix.Config

config :airbrake,
  api_key: System.get_env("AIRBRAKE_API_KEY") || "FAKEKEY",
  project_id: System.get_env("AIRBRAKE_PROJECT_ID") || 0,
  host: System.get_env("AIRBRAKE_HOST") || "https://airbrake.io"
