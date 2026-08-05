defmodule Estuary.Sink.Impl.Stdout do
  @behaviour Estuary.Sink

  alias Estuary.Validation

  @rules %{
    "format" => [nullable: true, type: :string, in: ["json", "pretty"]]
  }

  @impl true
  def validate(opts), do: Validation.run(opts, @rules)

  @impl true
  def init(opts) do
    with :ok <- validate(opts) do
      {:ok, %{format: Map.get(opts, "format", "json")}}
    end
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
