defmodule Estuary.Notification.Logs do
  @moduledoc """
  A single parsed `logsNotification` event for one transaction.
  """

  alias Estuary.Logs.Invocation

  @type t :: %__MODULE__{
          error: term(),
          invocations: [Invocation.t()],
          raw_logs: [String.t()],
          signature: String.t() | nil,
          slot: non_neg_integer() | nil
        }

  @derive Jason.Encoder
  @enforce_keys [:signature, :slot]
  defstruct [
    :signature,
    :slot,
    error: nil,
    raw_logs: [],
    invocations: []
  ]
end
