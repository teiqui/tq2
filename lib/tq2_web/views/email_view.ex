defmodule Tq2Web.EmailView do
  use Tq2Web, :view

  import Tq2.Utils.Urls, only: [app_uri: 0, store_uri: 0, web_uri: 0]

  alias Tq2.Sales.Order
  alias Tq2.Transactions.Cart

  defp format_money(%Money{} = money) do
    Money.to_string(money, symbol: true)
  end

  defp line_price(%Cart{price_type: "promotional"}, line) do
    format_money(line.promotional_price)
  end

  defp line_price(_, line) do
    format_money(line.price)
  end

  defp cart_total(%Cart{} = cart) do
    cart
    |> Cart.total()
    |> format_money()
  end

  defp line_total(cart, line) do
    Cart.line_total(cart, line) |> format_money()
  end

  defp order_date(%Order{inserted_at: inserted_at, account: %{time_zone: time_zone}}) do
    inserted_at
    |> Timex.to_datetime(time_zone)
    |> Timex.format!(dgettext("times", "%m/%d/%y"), :strftime)
  end

  defp order_time(%Order{inserted_at: inserted_at, account: %{time_zone: time_zone}}) do
    inserted_at
    |> Timex.to_datetime(time_zone)
    |> Timex.format!(dgettext("times", "%H:%Mh"), :strftime)
  end

  defp string_link(title, attrs) do
    title
    |> link(attrs)
    |> safe_to_string()
  end
end
