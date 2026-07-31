defmodule Pulse.Sink.Supervisor do
  @moduledoc """
  Starts one `Pulse.Sink.Server` per sink listed in the
  loaded config (see `Pulse.Config`).
  """

  require Logger

  use Supervisor

  @sink_modules %{
    "stdout" => Pulse.Sink.Stdout,
    "file" => Pulse.Sink.File
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
        Supervisor.child_spec({Pulse.Sink.Server, {module, opts}}, id: {module, idx})
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp sink_module!(type) do
    Map.get(@sink_modules, type) ||
      raise ArgumentError,
            "unknown sink type #{inspect(type)} -- expected one of #{inspect(Map.keys(@sink_modules))}"
  end
end
