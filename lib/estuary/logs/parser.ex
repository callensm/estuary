defmodule Estuary.Logs.Parser do
  alias Estuary.Anchor.Event
  alias Estuary.Anchor.Idl
  alias Estuary.Logs.Invocation
  alias Estuary.Notification.Logs

  @invoke_regex ~r/^Program (\w+) invoke \[(\d+)\]$/
  @consumed_regex ~r/^Program (\w+) consumed (\d+) of (\d+) compute units$/
  @return_regex ~r/^Program return: (\w+) (.+)$/
  @success_regex ~r/^Program (\w+) success$/
  @failed_regex ~r/^Program (\w+) failed: (.+)$/
  @log_prefix "Program log: "
  @data_prefix "Program data: "

  @spec parse(%{slot: term(), signature: term(), error: term(), logs: [String.t()]}, Idl.t()) ::
          Logs.t()
  def parse(%{slot: slot, signature: signature, error: error, logs: logs}, idl) do
    %Logs{
      error: error,
      invocations: parse_logs(logs, idl),
      raw_logs: logs,
      signature: signature,
      slot: slot
    }
  end

  @spec parse_logs([String.t()], Idl.t() | nil) :: [Invocation.t()]
  def parse_logs(logs, idl) do
    {completed, dangling} = Enum.reduce(logs, {[], []}, &process_line/2)

    invs =
      Enum.reduce(dangling, completed, fn frame, acc -> [finalize(frame) | acc] end)
      |> Enum.reverse()

    if is_nil(idl), do: invs, else: Enum.map(invs, &Event.enrich_invocation(&1, idl))
  end

  defp process_line(line, {completed, stack}) do
    cond do
      m = Regex.run(@invoke_regex, line) ->
        [_, program_id, depth] = m

        frame = %Invocation{
          program_id: program_id,
          depth: String.to_integer(depth)
        }

        {completed, [frame | stack]}

      m = Regex.run(@success_regex, line) ->
        [_, program_id] = m
        close_frame(completed, stack, program_id, :success, nil)

      m = Regex.run(@failed_regex, line) ->
        [_, program_id, error] = m
        close_frame(completed, stack, program_id, :failed, error)

      m = Regex.run(@consumed_regex, line) ->
        [_, _program_id, consumed, limit] = m

        stack =
          update_top(stack, fn f ->
            %{
              f
              | compute_units_consumed: String.to_integer(consumed),
                compute_units_limit: String.to_integer(limit)
            }
          end)

        {completed, stack}

      m = Regex.run(@return_regex, line) ->
        [_, program_id, data] = m

        stack =
          update_top(stack, fn f ->
            %{f | return_data: {program_id, safe_decode64(data)}}
          end)

        {completed, stack}

      String.starts_with?(line, @data_prefix) ->
        b64 = String.trim_leading(line, @data_prefix)
        decoded = safe_decode64(b64)
        stack = update_top(stack, fn f -> %{f | data: [decoded | f.data]} end)
        {completed, stack}

      String.starts_with?(line, @log_prefix) ->
        msg = String.trim_leading(line, @log_prefix)
        stack = update_top(stack, fn f -> %{f | logs: [msg | f.logs]} end)
        {completed, stack}

      true ->
        {completed, stack}
    end
  end

  defp close_frame(completed, [top | rest], _program_id, status, error) do
    closed = finalize(%{top | status: status, error: error})

    case rest do
      [parent | grandparents] ->
        parent = %{parent | children: [closed | parent.children]}
        {completed, [parent | grandparents]}

      [] ->
        {[closed | completed], []}
    end
  end

  defp close_frame(completed, [], _program_id, _status, _error), do: {completed, []}

  defp finalize(%Invocation{} = frame) do
    %{
      frame
      | logs: Enum.reverse(frame.logs),
        data: Enum.reverse(frame.data),
        children: Enum.reverse(frame.children)
    }
  end

  defp update_top([top | rest], fun), do: [fun.(top) | rest]
  defp update_top([], _fun), do: []

  defp safe_decode64(b64) do
    case Base.decode64(b64) do
      {:ok, bin} -> bin
      :error -> b64
    end
  end
end
