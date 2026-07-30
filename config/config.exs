import Config

config :pulse,
  ws_url: System.get_env("PULSE_WS_URL", "ws://127.0.0.1:8900"),
  commitment: System.get_env("PULSE_COMMITMENT", "confirmed"),
  program_id: System.get_env("PULSE_PROGRAM_ID", "11111111111111111111111111111111")
