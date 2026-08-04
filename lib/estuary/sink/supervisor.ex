defmodule Estuary.Sink.Supervisor do
  @moduledoc """
  Starts one `Estuary.Sink.Server` per sink listed in the
  loaded config (see `Estuary.Config`).
  """

  use Supervisor

  alias Estuary.Sink.Modules

  def start_link(sinks), do: Supervisor.start_link(__MODULE__, sinks, name: __MODULE__)

  @impl Supervisor
  def init(sinks) do
    children =
      sinks
      |> Enum.with_index()
      |> Enum.map(fn {%{type: type, opts: opts}, idx} ->
        module = Modules.sink_module!(type)
        Supervisor.child_spec({Estuary.Sink.Server, {module, opts}}, id: {module, idx})
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end
end
