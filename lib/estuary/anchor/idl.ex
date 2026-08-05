defmodule Estuary.Anchor.Idl do
  alias Estuary.Anchor.Event

  @type event :: %{
          name: String.t(),
          discriminator: binary(),
          fields: [map()]
        }

  @type t :: %{
          events: %{String.t() => event()},
          types: %{String.t() => map()}
        }

  @spec load!(String.t()) :: t()
  def load!(path) do
    File.read!(path) |> Jason.decode!() |> from_map()
  end

  @spec from_map(map()) :: t()
  def from_map(idl) do
    types = idl |> Map.get("types", []) |> Map.new(&{&1["name"], &1})
    events = idl |> Map.get("events", []) |> Enum.reduce(%{}, &resolve_event(&1, &2, types))
    %{events: events, types: types}
  end

  defp resolve_event(%{"name" => name, "fields" => fields} = event, acc, _types) do
    Map.put(acc, name, %{name: name, discriminator: discriminator(event, name), fields: fields})
  end

  defp resolve_event(%{"name" => name} = event, acc, types) do
    fields =
      case Map.get(types, name) do
        %{"type" => %{"kind" => "struct", "fields" => fields}} -> fields
        _ -> []
      end

    Map.put(acc, name, %{name: name, discriminator: discriminator(event, name), fields: fields})
  end

  defp discriminator(%{"discriminator" => bytes}, _name) when is_list(bytes),
    do: :binary.list_to_bin(bytes)

  defp discriminator(_event, name), do: Event.discriminator(name)
end
