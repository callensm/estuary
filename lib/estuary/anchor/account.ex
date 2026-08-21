defmodule Estuary.Anchor.Account do
  alias Estuary.Anchor.Borsh
  alias Estuary.Anchor.Idl
  alias Estuary.Notification.Program

  @spec enrich_notification(Program.t(), Idl.t()) :: Program.t()
  def enrich_notification(%Program{data: {data, encoding}} = program, idl) when is_binary(data) do
    case encoding do
      "base64" ->
        case decode_b64(safe_decode64(data), idl) do
          {:ok, _name, state} -> %{program | anchor_state: state}
          _ -> program
        end

      _ ->
        program
    end
  end

  def enrich_notification(program, _idl), do: program

  @spec discriminator(map(), String.t()) :: binary()
  def discriminator(%{"discriminator" => bytes}, _account_name) when is_list(bytes),
    do: :binary.list_to_bin(bytes)

  def discriminator(_account, account_name) do
    :crypto.hash(:sha256, "account:" <> account_name)
    |> binary_part(0, 8)
  end

  defp decode_b64(<<disc::binary-size(8), body::binary>>, %{
         accounts: accounts,
         types: types
       }) do
    case Enum.find(accounts, fn acc -> acc.discriminator == disc end) do
      nil ->
        {:unknown, disc}

      %{name: name, fields: fields} ->
        case Borsh.decode_fields(body, fields, types) do
          {:ok, decoded, _rest} -> {:ok, name, decoded}
          {:error, reason} -> {:error, reason}
        end
    end
  end

  defp decode_b64(data, _idl), do: {:error, {:payload_too_short, byte_size(data)}}

  defp safe_decode64(b64) when is_binary(b64) do
    case Base.decode64(b64) do
      {:ok, bin} -> bin
      :error -> b64
    end
  end
end
