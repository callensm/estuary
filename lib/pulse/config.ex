defmodule Pulse.Config do
  require Logger

  @default_ws_url "ws://127.0.0.1:8900"
  @default_commitment "confirmed"
  @default_program_id "11111111111111111111111111111111"

  @type sink_config :: %{type: String.t(), opts: map()}

  @type t :: %{
          ws_url: String.t(),
          commitment: String.t(),
          program_id: String.t(),
          sinks: [sink_config()]
        }

  @spec load(String.t() | nil) :: t()
  def load(path \\ nil) do
    raw = read_yaml(path || find_config_path())
    pulse = Map.get(raw, "pulse", %{})

    %{
      ws_url: coalesce(pulse, "ws_url", "PULSE_WS_URL", @default_ws_url),
      commitment: coalesce(pulse, "commitment", "PULSE_COMMITMENT", @default_commitment),
      program_id: coalesce(pulse, "program_id", "PULSE_PROGRAM_ID", @default_program_id),
      sinks: load_sinks(pulse)
    }
  end

  defp find_config_path() do
    cond do
      (path = System.get_env("PULSE_CONFIG")) && File.exists?(path) ->
        path

      File.exists?(".pulserc.yaml") ->
        ".pulserc.yaml"

      File.exists?(".pulserc.yml") ->
        ".pulserc.yml"

      true ->
        nil
    end
  end

  defp read_yaml(nil), do: %{}

  defp read_yaml(path) do
    case YamlElixir.read_from_file(path) do
      {:ok, data} when is_map(data) ->
        Logger.info("Configuration loaded from #{path}: \n#{inspect(data)}")
        data

      {:ok, _} ->
        Logger.warning("Configuration #{path} did not contain valid YAML")
        %{}

      {:error, reason} ->
        Logger.warning(
          "Configuration could not be read from #{path} (#{inspect(reason)}), falling back to environment"
        )

        %{}
    end
  end

  defp coalesce(map, key, env_var, default) do
    case Map.fetch(map, key) do
      {:ok, value} when not is_nil(value) -> value
      _ -> System.get_env(env_var, default)
    end
  end

  defp load_sinks(%{"sinks" => sinks}) when is_list(sinks) and sinks != [] do
    Enum.map(sinks, &normalize_sink/1)
  end

  defp load_sinks(_data) do
    [sink_from_env(System.get_env("PULSE_SINK_TYPE", "stdout"))]
  end

  defp normalize_sink(%{"type" => type} = sink) do
    %{type: type, opts: Map.drop(sink, ["type"])}
  end

  defp sink_from_env("stdout") do
    %{
      type: "stdout",
      opts: %{
        "format" => System.get_env("PULSE_STDOUT_FORMAT", "json")
      }
    }
  end

  defp sink_from_env("file") do
    %{
      type: "file",
      opts: %{
        "path" => System.get_env("PULSE_FILE_PATH", "./events.json")
      }
    }
  end
end
