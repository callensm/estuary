defmodule Estuary.WebSocket do
  @moduledoc """
  Supervisor child link implementation to wrap a websocket connection
  to a Solana RPC node for log notification subscriptions and data pipelining.

  Consumes `websocket_opts` as a link starting argument and internally tracks
  process state in the form of a private module `State.t()`.
  """

  use WebSockex

  require Logger

  alias Estuary.Anchor.Event
  alias Estuary.Anchor.Account
  alias Estuary.Config
  alias Estuary.Notification
  alias Estuary.WebSocket.State

  @account_subscription_request_id 1
  @log_subscription_request_id 2
  @program_subscription_request_id 3

  @type websocket_opts :: [
          {:commitment, String.t()},
          {:program, String.t()},
          {:url, String.t()}
        ]

  defmodule State do
    @type t :: %__MODULE__{
            commitment: String.t(),
            program: Config.program_config(),
            account_subscription_id: non_neg_integer() | nil,
            log_subscription_id: non_neg_integer() | nil,
            program_subscription_id: non_neg_integer() | nil,
            url: String.t()
          }

    @enforce_keys [
      :commitment,
      :program,
      :account_subscription_id,
      :log_subscription_id,
      :program_subscription_id,
      :url
    ]
    defstruct @enforce_keys
  end

  @spec start_link(websocket_opts) :: {:error, any()} | {:ok, pid()}
  def start_link(opts) do
    url = Keyword.fetch!(opts, :url)

    state = %State{
      commitment: Keyword.fetch!(opts, :commitment),
      program: Keyword.fetch!(opts, :program),
      account_subscription_id: nil,
      log_subscription_id: nil,
      program_subscription_id: nil,
      url: url
    }

    WebSockex.start_link(url, __MODULE__, state)
  end

  @impl true
  def handle_connect(_conn, state) do
    Logger.info("Connected to #{state.url}, subscribing to notifications: #{state.program.id}")

    if is_binary(state.program.account_notifications) do
      WebSockex.cast(
        self(),
        {:send_message,
         account_subscribe_frame(state.program.account_notifications, state.commitment)}
      )
    end

    if state.program.log_notifications do
      WebSockex.cast(
        self(),
        {:send_message, log_subscribe_frame(state.program.id, state.commitment)}
      )
    end

    if state.program.program_notifications do
      WebSockex.cast(
        self(),
        {:send_message, program_subscribe_frame(state.program.id, state.commitment)}
      )
    end

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
      {:ok, %{"method" => "accountNotification"} = decoded} ->
        handle_account_notification(decoded, state)

      {:ok, %{"method" => "logsNotification"} = decoded} ->
        handle_log_notification(decoded, state)

      {:ok, %{"method" => "programNotification"} = decoded} ->
        handle_program_notification(decoded, state)

      {:ok, %{"id" => @account_subscription_request_id, "result" => subscription_id}} ->
        Logger.info("Subscribed to account notifications with ID: #{subscription_id}")
        {:ok, %{state | account_subscription_id: subscription_id}}

      {:ok, %{"id" => @log_subscription_request_id, "result" => subscription_id}} ->
        Logger.info("Subscribed to log notifications with ID: #{subscription_id}")
        {:ok, %{state | log_subscription_id: subscription_id}}

      {:ok, %{"id" => @program_subscription_request_id, "result" => subscription_id}} ->
        Logger.info("Subscribed to program notifications with ID: #{subscription_id}")
        {:ok, %{state | program_subscription_id: subscription_id}}

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

  defp handle_account_notification(
         %{"params" => %{"result" => %{"context" => context, "value" => value}}},
         state
       ) do
    notification =
      Notification.Program.from_json(context, value)
      |> Account.enrich_notification(state.program.idl)

    Estuary.Dispatcher.broadcast(notification)

    {:ok, state}
  end

  defp handle_log_notification(
         %{"params" => %{"result" => %{"context" => context, "value" => value}}},
         state
       ) do
    notification =
      Notification.Logs.from_json(context, value)
      |> Event.enrich_notification(state.program.idl)

    Estuary.Dispatcher.broadcast(notification)

    {:ok, state}
  end

  defp handle_program_notification(
         %{"params" => %{"result" => %{"context" => context, "value" => value}}},
         state
       ) do
    notification =
      Notification.Program.from_json(context, value)
      |> Account.enrich_notification(state.program.idl)

    Estuary.Dispatcher.broadcast(notification)

    {:ok, state}
  end

  defp account_subscribe_frame(account, commitment) do
    Jason.encode!(%{
      id: @account_subscription_request_id,
      jsonrpc: "2.0",
      method: "accountSubscribe",
      params: [
        account,
        %{commitment: commitment, encoding: "base64"}
      ]
    })
  end

  defp log_subscribe_frame(program_id, commitment) do
    Jason.encode!(%{
      id: @log_subscription_request_id,
      jsonrpc: "2.0",
      method: "logsSubscribe",
      params: [
        %{mentions: [program_id]},
        %{commitment: commitment}
      ]
    })
  end

  defp program_subscribe_frame(program_id, commitment) do
    Jason.encode!(%{
      id: @program_subscription_request_id,
      jsonrpc: "2.0",
      method: "programSubscribe",
      params: [
        program_id,
        %{commitment: commitment, encoding: "base64"}
      ]
    })
  end
end
