defmodule Pulse.Application do
  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      {
        Pulse.WebSocket,
        [
          url: Application.get_env(:pulse, :ws_url),
          commitment: Application.get_env(:pulse, :commitment),
          program_id: Application.get_env(:pulse, :program_id)
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pulse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
