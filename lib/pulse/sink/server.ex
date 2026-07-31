defmodule Pulse.Sink.Server do
  use GenServer

  require Logger

  def start_link({module, opts}) do
    GenServer.start_link(__MODULE__, {module, opts})
  end

  @impl true
  def init({module, opts}) do
    case module.init(opts) do
      {:ok, state} ->
        {:ok, _} = Registry.register(Pulse.SinkRegistry, :sink, module)
        {:ok, %{module: module, state: state}}

      {:error, reason} ->
        Logger.error("Sink #{inspect(module)} failed to start: #{inspect(reason)}")
        {:stop, reason}
    end
  end

  @impl true
  def handle_cast({:event, notification}, %{module: module, state: state} = s) do
    case module.handle_event(notification, state) do
      {:ok, new_state} ->
        {:noreply, %{s | state: new_state}}

      {:error, reason, new_state} ->
        Logger.error("Sink #{inspect(module)} dropped an event: #{inspect(reason)}")
        {:noreply, %{s | state: new_state}}
    end
  end

  @impl true
  def terminate(_reason, %{module: module, state: state}) do
    if function_exported?(module, :terminate, 1) do
      module.terminate(state)
    end

    :ok
  end
end
