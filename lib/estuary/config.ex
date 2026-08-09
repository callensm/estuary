defmodule Estuary.Config do
  require Logger

  alias Estuary.Anchor.Idl
  alias Estuary.Validation

  @default_ws_url "ws://127.0.0.1:8900"
  @default_commitment "confirmed"

  @rc_rules %{
    "ws_url" => [required: true, type: :string, url: true],
    "commitment" => [
      nullable: true,
      type: :string,
      in: ["processed", "confirmed", "finalized"]
    ],
    "program" => [
      required: true,
      type: :map,
      map: %{
        "id" => [required: true, type: :string],
        "idl" => [nullable: true, type: :string],
        "subscribed_events" => [
          nullable: true,
          type: :list,
          list: [required: true, type: :string]
        ]
      }
    ],
    "sinks" => [
      nullable: true,
      type: :list,
      list: [
        required: true,
        type: :map,
        map: %{
          "type" => [required: true, type: :string]
        }
      ]
    ]
  }

  @type program_config :: %{
          id: String.t(),
          idl: Idl.t() | nil,
          subscribed_events: [String.t()] | nil
        }

  @type sink_config :: %{
          type: String.t(),
          opts: map()
        }

  @type t :: %{
          ws_url: String.t(),
          commitment: String.t(),
          program: program_config(),
          sinks: [sink_config()]
        }

  @spec load(String.t() | nil) :: t()
  def load(path \\ nil) do
    estuary = read_yaml(path || find_config_path())

    with :ok <- Validation.run(estuary, @rc_rules) do
      %{
        ws_url: coalesce(estuary, "ws_url", "ESTUARY_WS_URL", @default_ws_url),
        commitment: coalesce(estuary, "commitment", "ESTUARY_COMMITMENT", @default_commitment),
        program: load_program_config!(estuary),
        sinks: load_sink_configs(estuary)
      }
    end
  end

  defp find_config_path() do
    cond do
      (path = System.get_env("ESTUARY_CONFIG")) && File.exists?(path) ->
        path

      File.exists?(".estuaryrc.yaml") ->
        ".estuaryrc.yaml"

      File.exists?(".estuaryrc.yml") ->
        ".estuaryrc.yml"

      true ->
        nil
    end
  end

  defp read_yaml(nil), do: %{}

  defp read_yaml(path) do
    case YamlElixir.read_from_file(path) do
      {:ok, data} when is_map(data) ->
        Logger.info("Configuration loaded from #{path}")
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

  defp load_program_config!(%{"program" => %{"id" => id} = program}) do
    %{
      id: id,
      idl: Map.get(program, "idl") |> Idl.load!(),
      subscribed_events: Map.get(program, "subscribed_events", [])
    }
  end

  defp load_program_config!(_data), do: raise(ArgumentError, "missing program config")

  defp load_sink_configs(%{"sinks" => sinks}) when is_list(sinks) and sinks != [] do
    Enum.map(sinks, &normalize_sink/1)
  end

  defp load_sink_configs(_data) do
    [sink_from_env(System.get_env("ESTUARY_SINK_TYPE", "stdout"))]
  end

  defp normalize_sink(%{"type" => type} = sink) do
    %{type: type, opts: Map.drop(sink, ["type"])}
  end

  defp sink_from_env("file") do
    %{
      type: "file",
      opts: %{
        "path" => System.get_env("ESTUARY_FILE_PATH", "./events.jsonl")
      }
    }
  end

  defp sink_from_env("pubsub") do
    %{
      type: "pubsub",
      opts: %{
        credentials_file: System.get_env("GOOGLE_APPLICATION_CREDENTIALS"),
        project_id: System.get_env("ESTUARY_PUBSUB_PROJECT_ID", System.get_env("GCP_PROJECT")),
        topic: System.get_env("ESTUARY_PUBSUB_TOPIC"),
        host: System.get_env("ESTUARY_PUBSUB_HOST")
      }
    }
  end

  defp sink_from_env("rabbitmq") do
    %{
      type: "rabbitmq",
      opts: %{
        "url" => System.get_env("ESTUARY_RABBITMQ_URL"),
        "host" => System.get_env("ESTUARY_RABBITMQ_HOST"),
        "port" => System.get_env("ESTUARY_RABBITMQ_PORT"),
        "username" => System.get_env("ESTUARY_RABBITMQ_USERNAME"),
        "password" => System.get_env("ESTUARY_RABBITMQ_PASSWORD"),
        "vhost" => System.get_env("ESTUARY_RABBITMQ_VHOST"),
        "queue" => System.get_env("ESTUARY_RABBITMQ_QUEUE"),
        "exchange" => System.get_env("ESTUARY_RABBITMQ_EXCHANGE"),
        "exchange_type" => System.get_env("ESTUARY_RABBITMQ_EXCHANGE_TYPE"),
        "routing_key" => System.get_env("ESTUARY_RABBITMQ_ROUTING_KEY"),
        "durable" => System.get_env("ESTUARY_RABBITMQ_DURABLE"),
        "declare" => System.get_env("ESTUARY_RABBITMQ_DECLARE")
      }
    }
  end

  defp sink_from_env("sqs") do
    %{
      type: "sqs",
      opts: %{
        "queue_url" => System.get_env("ESTUARY_SQS_QUEUE_URL"),
        "region" => System.get_env("ESTUARY_SQS_REGION"),
        "endpoint_url" => System.get_env("ESTUARY_SQS_ENDPOINT_URL")
      }
    }
  end

  defp sink_from_env("stdout") do
    %{
      type: "stdout",
      opts: %{
        "format" => System.get_env("ESTUARY_STDOUT_FORMAT", "json")
      }
    }
  end

  defp sink_from_env("webhook") do
    %{
      type: "webhook",
      opts: %{
        "url" => System.get_env("ESTUARY_WEBHOOK_URL"),
        "timeout_ms" => System.get_env("ESTUARY_WEBHOOK_TIMEOUT_MS")
      }
    }
  end
end
