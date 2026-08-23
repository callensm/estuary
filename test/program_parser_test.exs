defmodule Estuary.ProgramParserTest do
  use ExUnit.Case, async: true

  alias Estuary.Anchor.Account
  alias Estuary.Config
  alias Estuary.Notification.Program

  setup do
    config = Config.load()

    {:ok,
     %{
       idl: config.program.idl,
       notification: %{
         "jsonrpc" => "2.0",
         "method" => "programNotification",
         "params" => %{
           "result" => %{
             "context" => %{
               "slot" => 583
             },
             "value" => %{
               "pubkey" => "BpdYYo2Vw1NVbzE2DqJxCX2xEfr42xvMYFU2dKd1CW57",
               "account" => %{
                 "lamports" => 0,
                 "data" => [
                   "yejxy9xEWS8h2VVyCU6nTRb0tzC2Zyi9dl3e3/l0Eg95wSX433/7z0BKlCYbCjmJZYgYA02ljGl79Dai/AXLV0G+WsX/lB56h3uN9mOkdSonpBB6w0thOzMIvNbU7Kf/x9+OyyL99uoPAgAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                   "base64"
                 ],
                 "owner" => "11111111111111111111111111111111",
                 "executable" => false,
                 "rentEpoch" => 0,
                 "space" => 0
               }
             }
           }
         }
       }
     }}
  end

  test "parses tracked account type data", %{idl: idl, notification: notif} do
    prog =
      Program.from_json(
        get_in(notif, ["params", "result", "context"]),
        get_in(notif, ["params", "result", "value"])
      )
      |> Account.enrich_notification(idl)

    assert prog.anchor_state != nil
  end
end
