defmodule Estuary.Notification.Logs do
  @moduledoc """
  A single parsed `logsNotification` event for one transaction.
  """

  alias Estuary.Logs.Invocation
  alias Estuary.Logs.Parser

  @type t :: %__MODULE__{
          error: term(),
          invocations: [Invocation.t()],
          raw_logs: [String.t()],
          signature: String.t() | nil,
          slot: non_neg_integer() | nil
        }

  @derive Jason.Encoder
  @enforce_keys [:error, :invocations, :raw_logs, :signature, :slot]
  defstruct @enforce_keys

  @spec from_json(map(), map()) :: t()
  def from_json(context, value) do
    raw_logs = Map.get(value, "logs", [])

    %__MODULE__{
      error: Map.get(value, "err"),
      invocations: raw_logs |> Parser.parse_logs(),
      raw_logs: raw_logs,
      signature: Map.get(value, "signature"),
      slot: Map.get(context, "slot")
    }
  end
end
