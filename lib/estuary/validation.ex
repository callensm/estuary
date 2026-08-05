defmodule Estuary.Validation do
  @moduledoc """
  Thin wrapper around the [`validate`](https://hexdocs.pm/validate) hex
  package for `c:Estuary.validate/1` implementations: runs a
  rules map against `opts` and formats the resulting
  `Validate.Validator.Error` structs into the plain string messages the
  `Sink` behaviour returns.

      @rules %{
        "queue_url" => [required: true, type: :string, url: true],
        "region" => [nullable: true, type: :string]
      }

      def validate(opts), do: Validation.run(opts, @rules)

  Cross-field checks (e.g. "queue OR (exchange + routing_key)") aren't
  expressible here -- `Validate`'s `custom:` rule only ever sees a single
  field's value, not the whole map -- so those stay as a small manual check
  in the sink itself, merged with this result.
  """

  @spec run(map(), map()) :: :ok | {:error, [String.t()]}
  def run(opts, rules) do
    case Validate.validate(opts, rules) do
      {:ok, _data} -> :ok
      {:error, errors} -> {:error, Enum.map(errors, &format/1)}
    end
  end

  defp format(%Validate.Validator.Error{path: [], message: message}), do: message

  defp format(%Validate.Validator.Error{path: path, message: message}) do
    key = Enum.map_join(path, ".", &to_string/1)
    "#{inspect(key)} #{message}"
  end
end
