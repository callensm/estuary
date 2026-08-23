defmodule Estuary.Notification.Program do
  @moduledoc """
  A single parsed `programNotification` event.
  """

  @type t :: %__MODULE__{
          pubkey: String.t(),
          owner: String.t(),
          slot: non_neg_integer(),
          space: non_neg_integer(),
          data: {String.t() | nil, String.t()},
          anchor_state: map() | nil
        }

  @derive Jason.Encoder
  @enforce_keys [:pubkey, :data, :owner, :slot, :space]
  defstruct [
    :pubkey,
    :owner,
    :slot,
    :space,
    :data,
    anchor_state: nil
  ]

  @spec from_json(map(), map()) :: t()
  def from_json(context, value) do
    %__MODULE__{
      pubkey: Map.get(value, "pubkey"),
      owner: get_in(value, ["account", "owner"]),
      slot: Map.get(context, "slot"),
      space: get_in(value, ["account", "space"]),
      data: get_in(value, ["account", "data"]) |> List.to_tuple(),
      anchor_state: nil
    }
  end
end

defimpl Jason.Encoder, for: Tuple do
  def encode(data, opts) when is_tuple(data) do
    Jason.Encode.list(Tuple.to_list(data), opts)
  end
end
