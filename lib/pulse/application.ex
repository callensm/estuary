defmodule Pulse.Application do
  @moduledoc false

  use Application

  @impl Application
  def start(_type, _args) do
    children = [
      Pulse.EventBus,
      {
        Pulse.WebSocket,
        [
          url: "ws://127.0.0.1:8900",
          commitment: "confirmed",
          program_id: "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pulse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
