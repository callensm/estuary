defmodule Estuary.Anchor.Event do
  @spec discriminator(String.t()) :: binary()
  def discriminator(event_name) do
    :crypto.hash(:sha256, "event:" <> event_name)
    |> binary_part(0, 8)
  end
end
