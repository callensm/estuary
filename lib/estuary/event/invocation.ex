defmodule Estuary.Event.Invocation do
  @moduledoc """
  One frame in the program invocation tree, corresponding to a single
  `Program <id> invoke [depth]` ... `Program <id> success|failed` block.
  Nested (CPI) calls appear in `children`.
  """

  @type status :: :success | :failed | :unknown

  @type t :: %__MODULE__{
          program_id: String.t(),
          depth: non_neg_integer(),
          status: status(),
          error: String.t() | nil,
          compute_units_consumed: non_neg_integer() | nil,
          comupte_units_limit: non_neg_integer() | nil,
          logs: [String.t()],
          data: [binary()],
          return_data: {String.t(), binary()} | nil,
          children: [t()]
        }

  @derive Jason.Encoder
  @enforce_keys [:program_id, :depth]
  defstruct [
    :program_id,
    :depth,
    status: :unknown,
    error: nil,
    compute_units_consumed: nil,
    comupte_units_limit: nil,
    logs: [],
    data: [],
    return_data: nil,
    children: []
  ]
end
