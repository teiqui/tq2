defmodule Tq2Web.OrderView do
  use Tq2Web, :view
  use Scrivener.HTML

  import Tq2Web.Utils, only: [localize_datetime: 1, invert: 1]
  import Tq2Web.LinkHelpers, only: [icon_link: 2]

  alias Tq2.Payments.Payment
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
end
