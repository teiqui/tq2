defmodule Utils do
  def invert(map) when is_map(map) do
    for {k, v} <- map, into: %{}, do: {v, k}
  end
end
