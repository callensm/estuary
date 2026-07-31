defmodule Pulse.WebSocket do
  use WebSockex

  require Logger

  alias Pulse.LogParser
  alias Pulse.WebSocket.State

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            commitment: String.t(),
            program_id: String.t(),
            subscription_id: non_neg_integer | nil,
            url: String.t()
          }

    @enforce_keys [:commitment, :program_id, :subscription_id, :url]
    defstruct @enforce_keys
  end

  @subscription_request_id 1

  @typep websocket_opts :: [
           {:commitment, String.t()},
           {:program_id, String.t()},
           {:subscription_id, non_neg_integer() | nil},
           {:url, String.t()}
         ]

  @spec start_link(websocket_opts) :: {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)

    state = %State{
      commitment: Keyword.fetch!(opts, :commitment),
      program_id: Keyword.fetch!(opts, :program_id),
      subscription_id: nil,
      url: url
    }

    WebSockex.start_link(url, __MODULE__, state)
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("Connected to #{state.url}, subscribing to #{state.program_id}")

    WebSockex.cast(self(), {:send_message, subscribe_frame(state.program_id, state.commitment)})

    {:ok, state}
  end

  @impl true
  def handle_disconnect(%{reason: reason}, state) do
    Logger.warning("Websocket disconnected: #{inspect(reason)}")
    {:ok, state}
  end

  @impl true
  def handle_cast({:send_message, message}, state) do
    {:reply, {:text, message}, state}
  end

  @impl true
  def handle_frame({:text, message}, state) do
    case Jason.decode(message) do
      {:ok, %{"method" => "logsNotification"} = decoded} ->
        handle_log_notification(decoded, state)

      {:ok, %{"id" => @subscription_request_id, "result" => subscription_id}} ->
        Logger.info("Subscribed with ID: #{subscription_id}")
        {:ok, %{state | subscription_id: subscription_id}}

      {:ok, %{"error" => error}} ->
        Logger.error("RPC error: #{inspect(error)}")
        {:ok, state}

      {:ok, _} ->
        {:ok, state}

      {:error, reason} ->
        Logger.error("Failed to decode socket frame: #{inspect(reason)}")
        {:ok, state}
    end
  end

  @impl true
  def handle_frame(_frame, state), do: {:ok, state}

  @impl true
  def terminate(reason, _state) do
    Logger.warning("Websocket is shutting down: #{inspect(reason)}")
    :ok
  end

  defp handle_log_notification(
         %{"params" => %{"result" => %{"context" => context, "value" => value}}},
         state
       ) do
    notification =
      LogParser.parse(%{
        error: Map.get(value, "err"),
        logs: Map.get(value, "logs", []),
        signature: Map.get(value, "signature"),
        slot: Map.get(context, "slot")
      })

    Pulse.Dispatcher.broadcast(notification)

    {:ok, state}
  end

  @spec subscribe_frame(String.t(), String.t()) :: String.t()
  defp subscribe_frame(program_id, commitment) do
    Jason.encode!(%{
      id: @subscription_request_id,
      jsonrpc: "2.0",
      method: "logsSubscribe",
      params: [
        %{mentions: [program_id]},
        %{commitment: commitment}
      ]
    })
  end
end
