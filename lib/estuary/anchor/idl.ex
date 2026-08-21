defmodule Estuary.Anchor.Idl do
  alias Estuary.Anchor.Account
  alias Estuary.Anchor.Event

  @type account :: %{
          name: String.t(),
          discriminator: binary() | nil
        }

  @type event :: %{
          name: String.t(),
          discriminator: binary(),
          fields: [map()]
        }

  @type t :: %{
          accounts: [account()],
          events: [event()],
          types: %{String.t() => map()}
        }

  @spec load!(String.t()) :: t()
  def load!(path) do
    File.read!(path) |> Jason.decode!() |> from_map()
  end

  @spec from_map(map()) :: t()
  def from_map(idl) do
    types = idl |> Map.get("types", []) |> Map.new(&{&1["name"], &1})
    accounts = idl |> Map.get("accounts", []) |> Enum.map(&resolve_account(&1, types))
    events = idl |> Map.get("events", []) |> Enum.map(&resolve_event(&1, types))
    %{accounts: accounts, events: events, types: types}
  end

  defp resolve_account(%{"name" => name, "fields" => fields} = account, _types) do
    %{name: name, discriminator: Account.discriminator(account, name), fields: fields}
  end

  defp resolve_account(%{"name" => name} = account, types) do
    fields =
      case Map.get(types, name) do
        %{"type" => %{"kind" => "struct", "fields" => fields}} -> fields
        _ -> []
      end

    %{name: name, discriminator: Account.discriminator(account, name), fields: fields}
  end

  defp resolve_event(%{"name" => name, "fields" => fields} = event, _types) do
    %{name: name, discriminator: Event.discriminator(event, name), fields: fields}
  end

  defp resolve_event(%{"name" => name} = event, types) do
    fields =
      case Map.get(types, name) do
        %{"type" => %{"kind" => "struct", "fields" => fields}} -> fields
        _ -> []
      end

    %{name: name, discriminator: Event.discriminator(event, name), fields: fields}
  end
end
