defmodule Pulse.LogNotification do
  @enforce_keys [:logs, :signature, :slot]
  defstruct [
    :err,
    :logs,
    :signature,
    :slot
  ]

  @type t :: %__MODULE__{
          err: map() | nil,
          logs: [String.t()],
          signature: String.t(),
          slot: non_neg_integer()
        }

  @spec new_from_value(map(), map()) :: t()
  def new_from_value(value, context) do
    %__MODULE__{
      err: Map.get(value, "err"),
      logs: Map.get(value, "logs", []),
      signature: Map.get(value, "signature"),
      slot: Map.get(context, "slot")
    }
  end
end
