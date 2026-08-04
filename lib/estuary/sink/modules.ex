defmodule Estuary.Sink.Modules do
  @sink_modules %{
    "file" => Estuary.Sink.Impl.File,
    "rabbitmq" => Estuary.Sink.Impl.Rabbitmq,
    "sqs" => Estuary.Sink.Impl.Sqs,
    "stdout" => Estuary.Sink.Impl.Stdout,
    "webhook" => Estuary.Sink.Impl.Webhook
  }

  def available(), do: Map.keys(@sink_modules)

  @spec sink_module(String.t()) :: {:ok, module()} | :error
  def sink_module(type), do: Map.fetch(@sink_modules, type)

  @spec sink_module!(String.t()) :: module()
  def sink_module!(type) do
    Map.get(@sink_modules, type) ||
      raise ArgumentError,
            "unknown sink type #{inspect(type)} -- expected one of #{inspect(available())}"
  end
end
