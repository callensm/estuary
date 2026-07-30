defmodule Pulse.LogNotification do
  @moduledoc false

  @enforce_keys [:logs, :signature, :slot]
  defstruct [
    :err,
    :logs,
    :signature,
    :slot
  ]

  @type t() :: %__MODULE__{
          err: map() | nil,
          logs: [String.t()],
          signature: String.t(),
          slot: non_neg_integer()
        }
end
