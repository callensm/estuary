defmodule Estuary.Sink.Kafka do
  @behaviour Estuary.Sink

  @impl true
  def init(%{"brokers" => brokers, "topc" => topic}) do
    broker_opt =
      brokers
      |> Enum.each(&parse_broker/1)
      |> Enum.map(fn [host, port] -> {host, port} end)

    case KafkaEx.API.start_client(broker: broker_opt) do
      {:ok, client} -> {:ok, %{client: client, topic: topic}}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl true
  def handle_event(notification, %{client: client, topic: topic} = state) do
    message = notification |> Jason.encode!()

    case KafkaEx.API.produce_one(client, topic, 0, message) do
      {:ok, _metadata} -> {:ok, state}
      {:error, reason} -> {:error, reason, state}
    end
  end

  @impl true
  def terminate(%{client: client}) do
    Process.exit(client, :kill)
    :ok
  end

  defp parse_broker(broker) do
    case String.split(broker, ":") do
      [host, port] ->
        [host, String.to_integer(port)]

      [host] ->
        [host, 9092]
    end
  end
end
