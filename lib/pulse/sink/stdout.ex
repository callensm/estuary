defmodule Pulse.Sink.Stdout do
  @behaviour Pulse.Sink

  @impl true
  def init(opts) do
    {:ok, %{format: Map.get(opts, "format", "json")}}
  end

  @impl true
  def handle_event(notification, %{format: "pretty"} = state) do
    IO.puts(pretty(notification))
    {:ok, state}
  end

  def handle_event(notification, state) do
    notification
    |> Jason.encode!()
    |> IO.puts()

    {:ok, state}
  end

  defp pretty(notification) do
    "[slot #{notification.slot}] #{notification.signature} " <>
      "error=#{inspect(notification.error)} invocations=#{length(notification.invocations)}"
  end
end
