defmodule Tq2Web.ButtonComponent do
  use Tq2Web, :live_component

  alias Tq2.Transactions.Cart

  def cart_total(%Cart{} = cart) do
    cart
    |> amounts()
    |> Enum.reduce(fn price, total -> Money.add(price, total) end)
    |> Money.to_string(symbol: true)
  end

  defp show_button?(%{lines: []}), do: false
  defp show_button?(_), do: true

  defp amounts(%Cart{price_type: "promotional", lines: lines}) do
    Enum.map(lines, &Money.multiply(&1.promotional_price, &1.quantity))
  end

  defp amounts(%Cart{price_type: "regular", lines: lines}) do
    Enum.map(lines, &Money.multiply(&1.price, &1.quantity))
  end
end
