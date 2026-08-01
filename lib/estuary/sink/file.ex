defmodule Estuary.Sink.File do
  @behaviour Estuary.Sink

  @impl true
  def init(%{"path" => path}) when is_binary(path) do
    File.mkdir_p!(Path.dirname(path))

    case File.open(path, [:append, :utf8]) do
      {:ok, io} -> {:ok, %{io: io, path: path}}
      {:error, reason} -> {:error, {:open_failed, path, reason}}
    end
  end

  def init(_opts), do: {:error, :missing_path}

  @impl true
  def handle_event(notification, %{io: io} = state) do
    line = Jason.encode!(notification)
    IO.write(io, line <> "\n")
    {:ok, state}
  end

  @impl true
  def terminate(%{io: io}), do: File.close(io)
end
