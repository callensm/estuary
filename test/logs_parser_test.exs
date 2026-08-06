defmodule Estuary.LogsParserTest do
  use ExUnit.Case

  require Logger

  alias Estuary.Logs.Parser

  test "parses list of log strings" do
    logs = [
      "Program ComputeBudget111111111111111111111111111111 invoke [1]",
      "Program ComputeBudget111111111111111111111111111111 success",
      "Program xnft5aaToUM4UFETUQfj7NUDUBdvYHTVhNFThEYTm55 invoke [1]",
      "Program log: Instruction: CreateInstall",
      "Program 11111111111111111111111111111111 invoke [2]",
      "Program 11111111111111111111111111111111 success",
      "Program data: zfkKUcOYon4Gca5r9bMRjVV0/hfOjFms70hEyOmWWJnrrA2O5nIMsA36lJIOHmXFX9JSOu7E8gvENIahQI+e9mmJ9YF3bZa8",
      "Program xnft5aaToUM4UFETUQfj7NUDUBdvYHTVhNFThEYTm55 consumed 17114 of 199850 compute units",
      "Program xnft5aaToUM4UFETUQfj7NUDUBdvYHTVhNFThEYTm55 success"
    ]

    invocations = Parser.parse_logs(logs)

    Logger.info(inspect(invocations, pretty: true))

    assert length(invocations) == 2 and length(Enum.at(invocations, 1).data) == 1
  end
end
