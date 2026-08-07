defmodule Estuary.Application do
  use Application

  alias Estuary.Config

  require Logger

  @impl Application
  def start(_type, _args) do
    config = Config.load()

    Logger.info(inspect(config, pretty: true))

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
          program: config.program
        ]
      }
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Estuary.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
