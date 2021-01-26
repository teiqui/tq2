defmodule Tq2Web.OrderView do
  use Tq2Web, :view
  use Scrivener.HTML

  import Tq2Web.Utils, only: [localize_datetime: 1, invert: 1]
  import Tq2Web.LinkHelpers, only: [icon_link: 2]

  alias Tq2.Payments.Payment
  alias Tq2.Sales.Order
  alias Tq2.Transactions.Cart

  @statuses %{
    dgettext("orders", "Pending") => "pending",
    dgettext("orders", "Processing") => "processing",
    dgettext("orders", "Completed") => "completed",
    dgettext("orders", "Canceled") => "canceled"
  }

  @cart_handing %{
    "pickup" => dgettext("orders", "Pickup"),
    "delivery" => dgettext("orders", "Delivery")
  }

  @payment_kinds %{
    "cash" => dgettext("payments", "Cash"),
    "mercado_pago" => dgettext("payments", "MercadoPago"),
    "wire_transfer" => dgettext("payments", "Wire transfer"),
    "other" => dgettext("payments", "Other")
  }

  def link_to_show(conn, order) do
    icon_link(
      "eye-fill",
      title: dgettext("orders", "Show"),
      to: Routes.order_path(conn, :show, order),
      class: "ml-2"
    )
  end

  def link_to_edit(conn, order) do
    icon_link(
      "pencil-fill",
      title: dgettext("orders", "Edit"),
      to: Routes.order_edit_path(conn, :index, order),
      class: "ml-2"
    )
  end

  def payment_kind(kind), do: @payment_kinds[kind]

  def format_money(%Money{} = money) do
    Money.to_string(money, symbol: true)
  end

  defp status(status), do: invert(@statuses)[status]

  defp type(%Order{cart: %{price_type: "promotional"}}) do
    dgettext("orders", "Teiqui")
  end

  defp type(_order) do
    dgettext("orders", "Regular")
  end

  defp cart_handing(type), do: @cart_handing[type]

  defp line_price(%Cart{price_type: "promotional"}, line) do
    format_money(line.promotional_price)
  end

  defp line_price(_, line) do
    format_money(line.price)
  end

  defp line_total(cart, line) do
    Cart.line_total(cart, line) |> format_money()
  end

  defp cart_total(%Cart{} = cart) do
    cart
    |> Cart.total()
    |> format_money()
  end

  defp pending_payment_alert(%Payment{status: "pending"}) do
    content_tag(:i, nil, class: "bi-exclamation-triangle")
  end

  defp pending_payment_alert(_), do: nil

  defp show_promotion_alert?(%Cart{price_type: "promotional"}), do: true
  defp show_promotion_alert?(_cart), do: false

  defp promotion_alert_class(%Order{parents: [], children: []} = order) do
    case DateTime.utc_now() |> DateTime.compare(order.promotion_expires_at) do
      :gt -> "danger"
      _ -> "warning"
    end
  end

  defp promotion_alert_class(%Order{} = _order) do
    "success"
  end

  defp promotion_alert_text(%Order{parents: [], children: []} = order) do
    case DateTime.utc_now() |> DateTime.compare(order.promotion_expires_at) do
      :gt ->
        dgettext(
          "orders",
          "This order has promotional price, but the time to join has expired (the limit was %{date})",
          date: localize_datetime(order.promotion_expires_at)
        )

      _ ->
        dgettext(
          "orders",
          "This order has promotional price, but none other has joined yet, time expires at <strong>%{date}</strong>",
          date: localize_datetime(order.promotion_expires_at)
        )
    end
  end

  defp promotion_alert_text(%Order{parents: [], children: children}) do
    dngettext(
      "orders",
      "This order has promotional price, and the customer has brought another one, so both gets the discount!",
      "This order has promotional price, and the customer has brought %{count} more, so all of them gets the discount!",
      Enum.count(children)
    )
  end

  defp promotion_alert_text(%Order{}) do
    dgettext(
      "orders",
      "This order has promotional price, and the customer join another, so both gets the discount!"
    )
  end
end
