defmodule Estuary.Anchor.Borsh do
  @moduledoc """
  Minimal Borsh decoder for the type shapes that show up in Anchor IDLs:
  fixed-width integers/floats, `bool`, `string`, `bytes`, `publicKey`/
  `pubkey`, `vec<T>`, `option<T>`, fixed-size arrays, and struct-shaped
  `defined` types (referencing another entry in the IDL's `types` section).

  Enum-shaped `defined` types (Rust-style tagged unions/discriminated
  enums) aren't supported yet -- decoding stops with
  `{:error, {:unsupported_type, name, "enum"}}` if one is encountered.
  Borsh itself is a small, stable format; this covers what Anchor actually
  emits in events, not the full spec.
  """

  @type type_spec :: String.t() | map()
  @type types_map :: %{String.t() => map()}

  @spec decode_type(binary(), type_spec(), types_map()) ::
          {:ok, term(), binary()} | {:error, term()}
  def decode(bin, type, types), do: decode_type(bin, type, types)

  @spec decode_fields(binary(), [map()], types_map()) :: {:ok, map(), binary()} | {:error, term()}
  def decode_fields(bin, fields, types) do
    Enum.reduce_while(
      fields,
      {:ok, %{}, bin},
      fn %{"name" => name, "type" => type}, {:ok, acc, rest} ->
        case decode_type(rest, type, types) do
          {:ok, value, inner_rest} -> {:cont, {:ok, Map.put(acc, name, value), inner_rest}}
          {:error, reason} -> {:halt, {:error, reason}}
        end
      end
    )
  end

  defp decode_type(<<value::little-unsigned-size(8), rest::binary>>, "u8", _types),
    do: {:ok, value, rest}

  defp decode_type(<<value::little-unsigned-size(16), rest::binary>>, "u16", _types),
    do: {:ok, value, rest}

  defp decode_type(<<value::little-unsigned-size(32), rest::binary>>, "u32", _types),
    do: {:ok, value, rest}

  defp decode_type(<<value::little-unsigned-size(64), rest::binary>>, "u64", _types),
    do: {:ok, value, rest}

  defp decode_type(<<value::little-signed-size(8), rest::binary>>, "i8", _types),
    do: {:ok, value, rest}

  defp decode_type(<<value::little-signed-size(16), rest::binary>>, "i16", _types),
    do: {:ok, value, rest}

  defp decode_type(<<value::little-signed-size(32), rest::binary>>, "i32", _types),
    do: {:ok, value, rest}

  defp decode_type(<<value::little-signed-size(64), rest::binary>>, "i64", _types),
    do: {:ok, value, rest}

  defp decode_type(<<value::little-signed-size(128), rest::binary>>, "i128", _types),
    do: {:ok, value, rest}

  defp decode_type(<<value::float-little-size(32), rest::binary>>, "f32", _types),
    do: {:ok, value, rest}

  defp decode_type(<<value::float-little-size(64), rest::binary>>, "f64", _types),
    do: {:ok, value, rest}

  defp decode_type(<<0, rest::binary>>, "bool", _types), do: {:ok, false, rest}
  defp decode_type(<<1, rest::binary>>, "bool", _types), do: {:ok, true, rest}

  defp decode_type(
         <<len::little-unsigned-size(32), str::binary-size(len), rest::binary>>,
         "string",
         _
       ),
       do: {:ok, str, rest}

  defp decode_type(_bin, "string", _types), do: {:error, :truncated_string}

  defp decode_type(
         <<len::little-unsigned-size(32), b::binary-size(len), rest::binary>>,
         "bytes",
         _
       ),
       do: {:ok, b, rest}

  defp decode_type(_data, "bytes", _), do: {:error, :truncated_bytes}

  defp decode_type(<<pubkey::binary-size(32), rest::binary>>, type, _types)
       when type in ["publicKey", "pubkey"], do: {:ok, Base58.encode(pubkey), rest}

  defp decode_type(bin, %{"vec" => elem_type}, types) do
    with {:ok, len, body} <- take_u32(bin) do
      decode_n(body, elem_type, types, len, [])
    end
  end

  defp decode_type(<<0, rest::binary>>, %{"option" => _elem_type}, _types), do: {:ok, nil, rest}

  defp decode_type(<<_tag, rest::binary>>, %{"option" => elem_type}, types),
    do: decode_type(rest, elem_type, types)

  defp decode_type(bin, %{"array" => [elem_type, count]}, types),
    do: decode_n(bin, elem_type, types, count, [])

  defp decode_type(bin, %{"defined" => defined}, types) do
    name = defined_name(defined)

    case Map.fetch(types, name) do
      {:ok, %{"type" => %{"kind" => "struct", "fields" => fields}}} ->
        decode_fields(bin, fields, types)

      {:ok, %{"type" => %{"kind" => other}}} ->
        {:error, {:unsupported_type, name, other}}

      :error ->
        {:error, {:unknown_defined_type, name}}
    end
  end

  defp decode_type(_bin, type, _types), do: {:error, {:unsupported_type, type}}

  defp defined_name(name) when is_binary(name), do: name
  defp defined_name(%{"name" => name}), do: name

  defp decode_n(bin, _elem_type, _types, 0, acc), do: {:ok, Enum.reverse(acc), bin}

  defp decode_n(bin, elem_type, types, n, acc) do
    case decode_type(bin, elem_type, types) do
      {:ok, value, rest} -> decode_n(rest, elem_type, types, n - 1, [value | acc])
      {:error, reason} -> {:error, reason}
    end
  end

  defp take_u32(<<len::little-unsigned-size(32), rest::binary>>), do: {:ok, len, rest}
  defp take_u32(_), do: {:error, :truncated_length}
end
