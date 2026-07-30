defmodule Pulse.Rpc do
  require Logger

  alias Pulse.LogNotification

  @spec get_transaction(LogNotification.t(), String.t(), String.t()) ::
          {:error, any()} | {:ok, map()}
  def get_transaction(notification, endpoint, commitment) do
    Logger.debug(notification.signature)

    payload =
      Jason.encode!(%{
        id: 1,
        jsonrpc: "2.0",
        method: "getTransaction",
        params: [
          notification.signature,
          %{
            commitment: commitment,
            encoding: "json",
            maxSupportedTransactionVersion: 0
          }
        ]
      })

    response =
      Finch.build(:post, endpoint, [{"Content-Type", "application/json"}], payload)
      |> Finch.request(Pulse.Finch)

    case response do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        parse_response_body(body)

      {:ok, response} ->
        {:error, {:http_error, response.status}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @spec parse_response_body(String.t()) :: {:error, any()} | {:ok, map()}
  defp parse_response_body(body) do
    case Jason.decode(body) do
      {:ok, %{"result" => result}} ->
        {:ok, result}

      {:ok, %{"error" => error}} ->
        {:error, error}

      error ->
        error
    end
  end
end
