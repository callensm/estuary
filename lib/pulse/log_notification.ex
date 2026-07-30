defmodule Pulse.LogNotification do
  alias Pulse.Invocation

  @type t :: %__MODULE__{
          error: term(),
          invocations: [Invocation.t()],
          raw_logs: [String.t()],
          signature: String.t() | nil,
          slot: non_neg_integer() | nil
        }

  @enforce_keys [:signature, :slot]
  defstruct [
    :signature,
    :slot,
    error: nil,
    raw_logs: [],
    invocations: []
  ]
end
