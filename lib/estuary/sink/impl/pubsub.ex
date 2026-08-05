defmodule Estuary.Sink.Impl.Pubsub do
  @behaviour Estuary.Sink

  alias Estuary.Validation

  @rules %{
    "project_id" => [required: true, type: :string],
    "topic" => [required: true, type: :string],
    "credentials_file" => [nullable: true, type: :string],
    "host" => [nullable: true, type: :string, url: true]
  }

  @impl true
  def validate(opts), do: Validation.run(opts, @rules)

  @impl true
  def init(opts) do
    with :ok <- validate(opts) do
      project_id = Map.fetch!(opts, "project_id")
      topic = Map.fetch!(opts, "topic")
      creds = Map.get(opts, "credentials_file", "GOOGLE_APPLICATION_CREDENTIALS")
      host = Map.get(opts, "host", "https://pubsub.googleapis.com")

      case File.read!(creds) |> Jason.decode() do
        {:ok, %{"access_token" => access_token}}
        when is_binary(access_token) and access_token != "" ->
          {:ok, %{access_token: access_token, host: host, project_id: project_id, topic: topic}}

        {:ok, _data} ->
          {:error, :missing_access_token}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @impl true
  def handle_event(notification, state) do
    url =
      "#{state.host}/v1/projects/#{state.project_id}/topics/#{state.topic}:publish"

    headers = [
      {"authorization", "Bearer " <> state.access_token},
      {"content-type", "application/json"}
    ]

    payload =
      %{messages: [%{data: Base.encode64(Jason.encode!(notification))}]}
      |> Jason.encode!()

    case :hackney.post(url, headers, payload, [:with_body]) do
      {:ok, status, _headers, _body} when status in 200..299 ->
        {:ok, state}

      {:ok, status, _headers, body} ->
        {:error, {:unexpected_status, status, body}, state}

      {:error, reason} ->
        {:error, reason, state}
    end
  end
end
