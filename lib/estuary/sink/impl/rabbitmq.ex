defmodule Estuary.Sink.Impl.Rabbitmq do
  @behaviour Estuary.Sink

  alias Estuary.Sink.Validation

  @rules %{
    "url" => [nullable: true, type: :string, url: true],
    "host" => [nullable: true, type: :string],
    "port" => [nullable: true, cast: :integer],
    "username" => [nullable: true, type: :string],
    "password" => [nullable: true, type: :string],
    "vhost" => [nullable: true, type: :string],
    "queue" => [nullable: true, type: :string],
    "exchange" => [nullable: true, type: :string],
    "routing_key" => [nullable: true, type: :string],
    "durable" => [nullable: true, cast: :boolean],
    "declare" => [nullable: true, cast: :boolean],
    "exchange_type" => [
      nullable: true,
      type: :string,
      in: ["direct", "topic", "fanout", "headers"]
    ]
  }

  @impl true
  def validate(opts) do
    field_result = Validation.run(opts, @rules)
    target_result = validate_target(opts)

    case {field_result, target_result} do
      {:ok, :ok} -> :ok
      {:ok, {:error, errors}} -> {:error, errors}
      {{:error, errors}, :ok} -> {:error, errors}
      {{:error, a}, {:error, b}} -> {:error, a ++ b}
    end
  end

  @impl true
  def init(opts) do
    with {:ok, target} <- build_target(opts),
         {:ok, conn} <- AMQP.Connection.open(connection_opts(opts)),
         {:ok, chan} <- AMQP.Channel.open(conn) do
      if truthy?(Map.get(opts, "declare", true)) do
        case declare(chan, opts, target) do
          :ok -> {:ok, %{conn: conn, chan: chan, target: target}}
          {:error, reason} -> {:error, reason}
        end
      else
        {:ok, %{conn: conn, chan: chan, target: target}}
      end
    end
  end

  @impl true
  def handle_event(notification, state) do
    payload = Jason.encode!(notification)
    %{exchange: exchange, routing_key: routing_key} = state.target

    case AMQP.Basic.publish(state.chan, exchange, routing_key, payload, persistent: true) do
      :ok -> {:ok, state}
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def terminate(%{conn: conn}), do: AMQP.Connection.close(conn)

  defp validate_target(opts) do
    queue = Map.get(opts, "queue")
    exchange = Map.get(opts, "exchange")
    routing_key = Map.get(opts, "routing_key")

    cond do
      present?(queue) ->
        :ok

      present?(exchange) and present?(routing_key) ->
        :ok

      present?(exchange) ->
        {:error, ["\"exchange\" requires \"routing_key\" to also be configured"]}

      true ->
        {:error, ["must set either \"queue\", or \"exchange\" with \"routing_key\""]}
    end
  end

  defp build_target(%{"exchange" => exchange} = opts)
       when is_binary(exchange) and exchange != "" do
    case Map.get(opts, "routing_key") do
      routing_key when is_binary(routing_key) and routing_key != "" ->
        exchange_type =
          case Map.get(opts, "exchange_type", "topic") do
            "direct" -> :direct
            "topic" -> :topic
            "fanout" -> :fanout
            "headers" -> :headers
            other -> raise ArgumentError, "unknown exchange_type: #{inspect(other)}"
          end

        {
          :ok,
          %{
            exchange: exchange,
            exchange_type: exchange_type,
            routing_key: routing_key,
            queue: nil
          }
        }

      _ ->
        {:error, :missing_routing_key}
    end
  end

  defp build_target(%{"queue" => queue}) when is_binary(queue) and queue != "" do
    {:ok, %{exchange: "", exchange_type: nil, routing_key: queue, queue: queue}}
  end

  defp build_target(_opts), do: {:error, :missing_queue_or_exchange}

  defp declare(chan, opts, %{queue: queue}) when is_binary(queue) do
    with {:ok, _info} <-
           AMQP.Queue.declare(chan, queue, durable: truthy?(Map.get(opts, "durable", true))) do
      :ok
    end
  end

  defp declare(chan, opts, %{exchange: exchange, exchange_type: type}) when exchange != "" do
    AMQP.Exchange.declare(chan, exchange, type, durable: truthy?(Map.get(opts, "durable", true)))
  end

  defp connection_opts(%{"url" => url}) when is_binary(url) and url != "", do: url

  defp connection_opts(opts) do
    [
      host: Map.get(opts, "host", "localhost"),
      port: Map.get(opts, "port", 5672) |> to_integer(),
      username: Map.get(opts, "username", "guest"),
      password: Map.get(opts, "password", "guest"),
      virtual_host: Map.get(opts, "vhost", "/")
    ]
  end

  defp to_integer(val) when is_integer(val), do: val
  defp to_integer(val) when is_binary(val), do: String.to_integer(val)

  defp truthy?(true), do: true
  defp truthy?("true"), do: true
  defp truthy?(_), do: false

  defp present?(val), do: is_binary(val) and val != ""
end
