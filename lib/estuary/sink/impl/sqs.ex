defmodule Estuary.Sink.Impl.Sqs do
  @behaviour Estuary.Sink

  alias Estuary.Sink.Validation

  @rules %{
    "queue_url" => [required: true, type: :string, url: true],
    "endpoint_url" => [nullable: true, type: :string, url: true],
    "region" => [nullable: true, type: :string]
  }

  @impl true
  def validate(opts), do: Validation.run(opts, @rules)

  @impl true
  def init(%{"queue_url" => queue_url} = opts) when is_binary(queue_url) do
    with :ok <- validate(opts), {:ok, request_opts} <- compile_request_opts(opts) do
      {:ok, %{queue_url: Map.fetch!(opts, "queue_url"), request_opts: request_opts}}
    end
  end

  @impl true
  def handle_event(notification, state) do
    message = Jason.encode!(notification)

    state.queue_url
    |> ExAws.SQS.send_message(message)
    |> ExAws.request(state.request_opts)
    |> case do
      {:ok, _resp} -> {:ok, state}
      {:error, reason} -> {:error, reason, state}
    end
  end

  defp compile_request_opts(opts) do
    with {:ok, endpoint_opts} <- endpoint_opts(Map.get(opts, "endpoint_url")) do
      request_opts = put_opt(endpoint_opts, :region, Map.get(opts, "region"))
      {:ok, request_opts}
    end
  end

  defp endpoint_opts(nil), do: {:ok, []}

  defp endpoint_opts(endpoint_url) do
    case URI.parse(endpoint_url) do
      %URI{scheme: scheme, host: host, port: port} when is_binary(scheme) and is_binary(host) ->
        {:ok, [scheme: scheme <> "://", host: host, port: port]}

      _ ->
        {:error, {:invalid_endpoint_url, endpoint_url}}
    end
  end

  defp put_opt(list, _key, nil), do: list
  defp put_opt(list, key, value), do: Keyword.put(list, key, value)
end
