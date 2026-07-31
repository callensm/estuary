defmodule Estuary.Sink.Supervisor do
  @moduledoc """
  Starts one `Estuary.Sink.Server` per sink listed in the
  loaded config (see `Estuary.Config`).
  """

  require Logger

  use Supervisor

  @sink_modules %{
    "file" => Estuary.Sink.File,
    "kafka" => Estuary.Sink.Kafka,
    "sqs" => Estuary.Sink.Sqs,
    "stdout" => Estuary.Sink.Stdout
  }

  def start_link(sinks), do: Supervisor.start_link(__MODULE__, sinks, name: __MODULE__)

  @impl Supervisor
  def init(sinks) do
    Logger.info(inspect(sinks))

    children =
      sinks
      |> Enum.with_index()
      |> Enum.map(fn {%{type: type, opts: opts}, idx} ->
        module = sink_module!(type)
        Supervisor.child_spec({Estuary.Sink.Server, {module, opts}}, id: {module, idx})
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp sink_module!(type) do
    Map.get(@sink_modules, type) ||
      raise ArgumentError,
            "unknown sink type #{inspect(type)} -- expected one of #{inspect(Map.keys(@sink_modules))}"
  end
end
