defmodule Estuary.Sink.File do
  @behaviour Estuary.Sink

  @impl true
  def init(%{"path" => path}) when is_binary(path) do
    case normalize_path(path) do
      {:ok, n_path} ->
        File.mkdir_p!(Path.dirname(n_path))

        case File.open(path, [:append, :utf8]) do
          {:ok, io} -> {:ok, %{io: io, path: n_path}}
          {:error, reason} -> {:error, {:open_failed, n_path, reason}}
        end

      {:error, reason} ->
        {:error, reason}
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

  defp normalize_path(path) do
    cond do
      String.ends_with?("jsonl", path) ->
        {:ok, path}

      String.ends_with?("json", path) ->
        {:ok, path <> "l"}

      true ->
        {:error, :invalid_file_extension}
    end
  end
end
