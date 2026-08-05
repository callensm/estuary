defmodule Estuary.Sink do
  @moduledoc """
  Behaviour implemented by every event sink (stdout, file, sqs, kafka, ...).

  Each sink runs in its own supervised `Estuary.Sink.Server`
  process. `init/1` is called once at startup with that sink's `opts` map
  (straight from `.estuaryrc.yaml` / env, string keys); `handle_event/2` is
  called for every parsed log notification.

  A sink that fails to init (e.g. missing required config) should return
  `{:error, reason}` -- this crashes that one sink's supervised process
  (logged clearly) without taking down the rest of the app or the websocket
  client.

  A sink whose `handle_event/2` fails should return `{:error, reason, state}`
  rather than raising, so a single bad/unreachable delivery doesn't crash the
  sink and drop every event behind it.
  """

  alias Estuary.Logs.Notification

  @callback validate(opts :: map()) :: :ok | {:error, [String.t()]}

  @callback init(opts :: map()) :: {:ok, state :: term()} | {:error, term()}

  @callback handle_event(Notification.t(), state :: term()) ::
              {:ok, term()} | {:error, term(), term()}

  @callback terminate(state :: term()) :: :ok

  @optional_callbacks terminate: 1
end
