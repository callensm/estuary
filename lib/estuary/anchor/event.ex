defmodule Estuary.Anchor.Event do
  alias Estuary.Anchor.Borsh
  alias Estuary.Anchor.Idl
  alias Estuary.Logs.Invocation

  @spec enrich_invocation(Invocation.t(), Idl.t()) :: Invocation.t()
  def enrich_invocation(%Invocation{} = invocation, idl) do
    decoded_events =
      invocation.data
      |> Enum.map(&decode(&1, idl))
      |> Enum.flat_map(fn
        {:ok, name, fields} -> [%{event: name, fields: fields}]
        {:unknown, _disc} -> []
        {:error, _reason} -> []
      end)

    %{
      invocation
      | anchor_events: decoded_events,
        children: Enum.map(invocation.children, &enrich_invocation(&1, idl))
    }
  end

  @spec discriminator(map(), String.t()) :: binary()
  def discriminator(%{"discriminator" => bytes}, _event_name) when is_list(bytes),
    do: :binary.list_to_bin(bytes)

  def discriminator(_event, event_name) do
    :crypto.hash(:sha256, "event:" <> event_name)
    |> binary_part(0, 8)
  end

  defp decode(<<disc::binary-size(8), body::binary>>, %{events: events, types: types}) do
    case Enum.find(events, fn event -> event.discriminator == disc end) do
      nil ->
        {:unknown, disc}

      %{name: name, fields: fields} ->
        case Borsh.decode_fields(body, fields, types) do
          {:ok, decoded, _rest} -> {:ok, name, decoded}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp decode(payload, _idl), do: {:error, {:payload_too_short, byte_size(payload)}}
end
