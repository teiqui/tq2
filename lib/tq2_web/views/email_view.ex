defmodule Tq2Web.EmailView do
  use Tq2Web, :view

  alias Tq2.Transactions.Cart

  defp format_money(%Money{} = money) do
    Money.to_string(money, symbol: true)
  end

  defp cart_total(%Cart{} = cart) do
    cart
    |> Cart.total()
    |> format_money()
  end

  defp line_total(cart, line) do
    Cart.line_total(cart, line) |> format_money()
  end
end
