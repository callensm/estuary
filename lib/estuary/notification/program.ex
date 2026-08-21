defmodule Estuary.Notification.Program do
  @moduledoc """
  A single parsed `programNotification` event.
  """

  @type t :: %__MODULE__{
          pubkey: String.t(),
          owner: String.t(),
          space: non_neg_integer(),
          data: {String.t() | nil, String.t()},
          anchor_state: map() | nil
        }

  @derive Jason.Encoder
  @enforce_keys [:pubkey, :data, :owner, :space]
  defstruct [
    :pubkey,
    :owner,
    :space,
    :data,
    anchor_state: nil
  ]

  @spec from_json(map()) :: t()
  def from_json(value) do
    %__MODULE__{
      pubkey: Map.get(value, "pubkey"),
      owner: get_in(value, ["account", "owner"]),
      space: get_in(value, ["account", "space"]),
      data: get_in(value, ["account", "data"]) |> List.to_tuple(),
      anchor_state: nil
    }
  end
end
