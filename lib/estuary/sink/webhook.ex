defmodule Estuary.Sink.Webhook do
  @behaviour Estuary.Sink

  @impl true
  def init(%{"url" => url} = opts) when is_binary(url) and url != "" do
    case URI.parse(url) do
      %URI{scheme: scheme, host: host} when is_binary(scheme) and is_binary(host) ->
        timeout = opts |> Map.get("timeout_ms", 5_000) |> to_integer()
        headers = compile_headers(Map.get(opts, "headers", %{}))
        {:ok, %{url: url, headers: headers, timeout: timeout}}

      _ ->
        {:error, {:invalid_url, url}}
    end

    {:ok, %{url: url}}
  end

  def init(_opts), do: {:error, :missing_url}

  @impl true
  def handle_event(notification, state) do
    body = Jason.encode!(notification)
    options = [:with_body, {:recv_timeout, state.timeout, {:connect_timeout, state.timeout}}]

    case :hackney.post(state.url, state.headers, body, options) do
      {:ok, status, _headers, _body} when status in 200..299 ->
        {:ok, state}

      {:ok, status, _headers, body} ->
        {:error, {:unexpected_status, status, body}, state}

      {:error, reason} ->
        {:error, reason, state}
    end
  end

  defp compile_headers(headers) when is_map(headers) do
    extra = Enum.map(headers, fn {k, v} -> {to_string(k), to_string(v)} end)
    [{"content-type", "application/json"} | extra]
  end

  defp to_integer(val) when is_integer(val), do: val
  defp to_integer(val) when is_binary(val), do: String.to_integer(val)
end
