defmodule Pulse.LogHandler do
  require Logger

  alias Pulse.LogParser
  alias Pulse.LogNotification

  @spec handle_event(LogNotification.t()) :: :ok
  def handle_event(%LogNotification{} = notif) do
    program_id = Application.get_env(:pulse, :program_id)

    notif
    |> Map.get(:invocations)
    |> LogParser.find_invocations(program_id)
    |> Enum.each(&log_frame(&1, notif))

    :ok
  end

  defp log_frame(frame, notif) do
    Logger.info(
      "[#{notif.signature}] #{frame.program_id} #{frame.status} " <>
        "(#{length(frame.logs)} log lines, #{length(frame.data)} data payloads)"
    )

    Enum.each(frame.logs, &Logger.debug("  log: #{&1}"))
  end
end
