defmodule Estuary.Logs.Invocation do
  @moduledoc """
  One frame in the program invocation tree, corresponding to a single
  `Program <id> invoke [depth]` ... `Program <id> success|failed` block.
  Nested (CPI) calls appear in `children`.
  """

  @type status :: :success | :failed | :unknown

  @type t :: %__MODULE__{
          anchor_events: [map()] | nil,
          children: [t()],
          compute_units_consumed: non_neg_integer() | nil,
          compute_units_limit: non_neg_integer() | nil,
          data: [binary()],
          depth: non_neg_integer(),
          error: String.t() | nil,
          logs: [String.t()],
          program_id: String.t(),
          status: status()
        }

  @derive Jason.Encoder
  @enforce_keys [:program_id, :depth]
  defstruct [
    :program_id,
    :depth,
    status: :unknown,
    anchor_events: nil,
    data: [],
    error: nil,
    children: [],
    compute_units_consumed: nil,
    compute_units_limit: nil,
    logs: []
  ]
end
