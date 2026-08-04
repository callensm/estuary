defmodule Estuary.Sink.Impl.File do
  @behaviour Estuary.Sink

  alias Estuary.Sink.Validation

  @rules %{
    "path" => [required: true, type: :string, ends_with: "jsonl"]
  }

  @impl true
  def validate(opts), do: Validation.run(opts, @rules)

  @impl true
  def init(opts) do
    with :ok <- validate(opts) do
      path = Map.fetch!(opts, "path")
      File.mkdir_p!(Path.dirname(path))

      case File.open(path, [:append, :utf8]) do
        {:ok, io} -> {:ok, %{io: io, path: path}}
        {:error, reason} -> {:error, {:open_failed, path, reason}}
      end
    end
  end

  @impl true
  def handle_event(notification, %{io: io} = state) do
    line = Jason.encode!(notification)
    IO.write(io, line <> "\n")
    {:ok, state}
  end

  @impl true
  def terminate(%{io: io}), do: File.close(io)
end
