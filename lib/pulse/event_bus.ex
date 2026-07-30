defmodule Pulse.EventBus do
  @moduledoc false

  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def subscribe(pid \\ self()) do
    GenServer.cast(__MODULE__, {:subscribe, pid})
  end

  def publish(event) do
    GenServer.cast(__MODULE__, {:publish, event})
  end

  @impl GenServer
  def init(_) do
    {:ok, MapSet.new()}
  end

  @impl GenServer
  def handle_cast({:subscribe, pid}, subscribers) do
    Process.monitor(pid)
    {:noreply, MapSet.put(subscribers, pid)}
  end

  @impl GenServer
  def handle_cast({:publish, event}, subscribers) do
    Enum.each(subscribers, &send(&1, {:pulse_event, event}))
    {:noreply, subscribers}
  end
end
