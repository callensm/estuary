defmodule Estuary.Application do
  use Application

  alias Estuary.Config

  @impl Application
  def start(_type, _args) do
    config = Config.load()

    children = [
      {
        Registry,
        [
          keys: {:duplicate, :key},
          name: Estuary.SinkRegistry
        ]
      },
      {
        Estuary.Sink.Supervisor,
        config.sinks
      },
      {
        Estuary.WebSocket,
        [
          url: config.ws_url,
          commitment: config.commitment,
          program_id: config.program_id
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Estuary.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
