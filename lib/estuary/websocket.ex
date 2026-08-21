defmodule Estuary.WebSocket do
  @moduledoc """
  Supervisor child link implementation to wrap a websocket connection
  to a Solana RPC node for log notification subscriptions and data pipelining.

  Consumes `websocket_opts` as a link starting argument and internally tracks
  process state in the form of a private module `State.t()`.
  """

  use WebSockex

  require Logger

  alias Estuary.Anchor.Account
  alias Estuary.Config
  alias Estuary.Logs.Parser
  alias Estuary.Notification.Program
  alias Estuary.WebSocket.State

  @subscription_request_id 1

  @type websocket_opts :: [
          {:commitment, String.t()},
          {:program, String.t()},
          {:subscription_id, non_neg_integer() | nil},
          {:url, String.t()}
        ]

  defmodule State do
    @moduledoc false
    @type t :: %__MODULE__{
            commitment: String.t(),
            program: Config.program_config(),
            subscription_id: non_neg_integer | nil,
            url: String.t()
          }

    @enforce_keys [:commitment, :program, :subscription_id, :url]
    defstruct @enforce_keys
  end

  @spec start_link(websocket_opts) :: {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)

    state = %State{
      commitment: Keyword.fetch!(opts, :commitment),
      program: Keyword.fetch!(opts, :program),
      subscription_id: nil,
      url: url
    }

    WebSockex.start_link(url, __MODULE__, state)
  end

  @impl true
  def handle_connect(_conn, %State{program: %{subscribed_account_types: [_]}} = state) do
    Logger.info(
      "Connected to #{state.url}, subscribing to program account notifications: #{state.program.id} - #{inspect(state.program.subscribed_account_types)}"
    )

    WebSockex.cast(
      self(),
      {:send_message, program_subscribe_frame(state.program.id, state.commitment)}
    )

    {:ok, state}
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info(
      "Connected to #{state.url}, subscribing to log notifications: #{state.program.id}"
    )

    WebSockex.cast(
      self(),
      {:send_message, log_subscribe_frame(state.program.id, state.commitment)}
    )

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

      {:ok, %{"method" => "programNotification"} = decoded} ->
        handle_program_notification(decoded, state)

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
      Parser.parse(
        %{
          error: Map.get(value, "err"),
          logs: Map.get(value, "logs", []),
          signature: Map.get(value, "signature"),
          slot: Map.get(context, "slot")
        },
        state.program.idl
      )

    Estuary.Dispatcher.broadcast(notification)

    {:ok, state}
  end

  defp handle_program_notification(
         %{"params" => %{"result" => %{"value" => value}}},
         state
       ) do
    notification = Program.from_json(value) |> Account.enrich_notification(state.program.idl)

    Estuary.Dispatcher.broadcast(notification)

    {:ok, state}
  end

  defp program_subscribe_frame(program_id, commitment) do
    Jason.encode!(%{
      id: @subscription_request_id,
      jsonrpc: "2.0",
      method: "programSubscribe",
      params: [
        program_id,
        %{commitment: commitment, encoding: "base64"}
      ]
    })
  end

  defp log_subscribe_frame(program_id, commitment) do
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
