defmodule Estuary.Sink.Sqs do
  @behaviour Estuary.Sink

  @impl true
  def init(%{"queue_url" => queue_url}) when is_binary(queue_url) do
    {:ok, %{queue_url: queue_url, request_opts: []}}
  end

  def init(%{"queue_url" => queue_url, "region" => region}) when is_binary(queue_url) do
    {:ok, %{queue_url: queue_url, request_opts: [region: region]}}
  end

  def init(_opts), do: {:error, :missing_queue_url}

  @impl true
  def handle_event(notification, state) do
    message = notification |> Jason.encode!()

    state.queue_url
    |> ExAws.SQS.send_message(message)
    |> ExAws.request(state.request_opts)
    |> case do
      {:ok, _resp} -> {:ok, state}
      {:error, reason} -> {:error, reason, state}
    end
  end
end
