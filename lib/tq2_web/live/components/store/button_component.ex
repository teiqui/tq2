defmodule Tq2Web.Store.ButtonComponent do
  use Tq2Web, :live_component

  import Tq2Web.Utils, only: [format_money: 1]

  alias Tq2.Transactions.Cart
  alias Tq2Web.Store.{OptionsComponent, ShareComponent}

  def cart_total(%Cart{} = cart) do
    cart |> Cart.total() |> format_money()
  end

  defp show_button?(%{lines: []}), do: false
  defp show_button?(_), do: true
end
