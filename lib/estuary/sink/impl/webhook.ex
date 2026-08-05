defmodule Estuary.Sink.Impl.Webhook do
  @behaviour Estuary.Sink

  alias Estuary.Validation

  @rules %{
    "url" => [required: true, type: :string, url: true],
    "timeout_ms" => [nullable: true, cast: :integer],
    "headers" => [nullable: true, type: :map]
  }

  @impl true
  def validate(opts), do: Validation.run(opts, @rules)

  @impl true
  def init(opts) do
    with :ok <- validate(opts) do
      timeout = opts |> Map.get("timeout_ms", 5_000) |> to_integer()
      headers = compile_headers(Map.get(opts, "headers", %{}))
      {:ok, %{url: Map.fetch!(opts, "url"), headers: headers, timeout: timeout}}
    end
  end

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
