defmodule Pulse.Event do
  @enforce_keys [:program_id, :signature, :slot]
  defstruct [
    :compute_units,
    :inner_instruction_index,
    :instruction_index,
    :program_id,
    :signature,
    :slot,
    :timestamp,
    accounts: [],
    logs: [],
    metadata: %{}
  ]

  @type t :: %__MODULE__{
          accounts: list(String.t()),
          compute_units: non_neg_integer() | nil,
          inner_instruction_index: non_neg_integer() | nil,
          instruction_index: non_neg_integer() | nil,
          logs: list(String.t()),
          metadata: map(),
          program_id: String.t(),
          signature: String.t(),
          slot: pos_integer(),
          timestamp: DateTime.t() | nil
        }
end
