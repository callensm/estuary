defmodule Estuary.Sink.Webhook do
  @behaviour Estuary.Sink

  @impl true
  def init(%{"url" => url}) when is_binary(url) do
    {:ok, %{url: url}}
  end

  @impl true
  def handle_event(notification, %{url: url} = state) do
    payload = Jason.encode!(notification)

    :hackney.post(
      url,
      [{"Content-Type", "application/json"}],
      payload,
      [:with_body]
    )

    {:ok, state}
  end
end
