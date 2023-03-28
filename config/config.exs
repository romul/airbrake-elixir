use Mix.Config

config :airbrake,
  api_key: {:system, "AIRBRAKE_API_KEY", "FAKEKEY"},
  project_id: {:system, "AIRBRAKE_PROJECT_ID", 0},
  host: {:system, "AIRBRAKE_HOST", "https://airbrake.io"},
  filter_parameters: ["password"],
  filter_headers: ["authorization"]
