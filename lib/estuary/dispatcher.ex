defmodule Estuary.Dispatcher do
  @moduledoc """
  Fans out each parsed `Estuary.Notification.Logs` to every running sink. Wired in as
  the websocket client's `:handler` by default (see `Application.start/2`).
  """

  alias Estuary.Notification.Logs
  alias Estuary.Notification.Program

  @spec broadcast(Logs.t() | Program.t()) :: :ok
  def broadcast(notification) do
    Registry.dispatch(Estuary.SinkRegistry, :sink, fn entries ->
      for {pid, _module} <- entries do
        GenServer.cast(pid, {:event, notification})
      end
    end)

    :ok
  end
end
