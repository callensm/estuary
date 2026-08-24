defmodule Estuary.LogsParserTest do
  use ExUnit.Case, async: true

  alias Estuary.Anchor.Event
  alias Estuary.Config
  alias Estuary.Logs.Parser
  alias Estuary.Notification.Logs

  setup do
    config = Config.load()

    {:ok,
     %{
       idl: config.program.idl,
       notification: %{
         "jsonrpc" => "2.0",
         "method" => "logsNotification",
         "params" => %{
           "result" => %{
             "context" => %{
               "slot" => 123
             },
             "value" => %{
               "err" => nil,
               "signature" => "abc123",
               "logs" => [
                 "Program ComputeBudget111111111111111111111111111111 invoke [1]",
                 "Program ComputeBudget111111111111111111111111111111 success",
                 "Program xnft5aaToUM4UFETUQfj7NUDUBdvYHTVhNFThEYTm55 invoke [1]",
                 "Program log: Instruction: CreateInstall",
                 "Program 11111111111111111111111111111111 invoke [2]",
                 "Program 11111111111111111111111111111111 success",
                 "Program data: zfkKUcOYon4Gca5r9bMRjVV0/hfOjFms70hEyOmWWJnrrA2O5nIMsA36lJIOHmXFX9JSOu7E8gvENIahQI+e9mmJ9YF3bZa8",
                 "Program data: ofqaJZ/07UoCcpRiKu/z0QL+CExgqZGnBCjizyjE8xCJaPlJ2Uc+l/U=",
                 "Program xnft5aaToUM4UFETUQfj7NUDUBdvYHTVhNFThEYTm55 consumed 17114 of 199850 compute units",
                 "Program xnft5aaToUM4UFETUQfj7NUDUBdvYHTVhNFThEYTm55 success"
               ]
             }
           }
         }
       }
     }}
  end

  test "parses list of log strings", %{idl: idl, notification: notif} do
    notification =
      Logs.from_json(
        get_in(
          notif,
          ["params", "result", "context"]
        ),
        get_in(notif, ["params", "result", "value"])
      )
      |> Event.enrich_notification(idl)

    assert length(notification.invocations) == 2 and
             length(Enum.at(notification.invocations, 1).data) == 2
  end
end
