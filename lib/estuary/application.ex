defmodule Estuary.Application do
  use Application

  require Logger

  @impl Application
  def start(_type, _args) do
    config = Estuary.Config.load()

    Logger.info(inspect(config, pretty: true))

    children = [
      {Registry, [keys: {:duplicate, :key}, name: Estuary.SinkRegistry]},
      {Estuary.Sink.Supervisor, config.sinks},
      {
        Estuary.WebSocket,
        [
          url: config.ws_url,
          commitment: config.commitment,
          program: config.program
        ]
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: Estuary.Supervisor)
  end
end
