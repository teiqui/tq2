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
    "mercado_pago" => dgettext("payments", "MercadoPago")
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
      to: Routes.order_path(conn, :edit, order),
      class: "ml-2"
    )
  end

  def lock_version_input(form, order) do
    hidden_input(form, :lock_version, value: order.lock_version)
  end

  def submit_button do
    dgettext("orders", "Update")
    |> submit(class: "btn btn-primary rounded-pill font-weight-semi-bold")
  end

  defp statuses, do: @statuses

  defp status(status), do: invert(@statuses)[status]

  defp cart_handing(type), do: @cart_handing[type]

  defp line_total(cart, line) do
    Cart.line_total(cart, line) |> format_money()
  end

  defp format_money(%Money{} = money) do
    Money.to_string(money, symbol: true)
  end

  defp cart_total(%Cart{} = cart) do
    cart
    |> Cart.total()
    |> format_money()
  end

  defp pending_payment_alert(%Payment{status: "pending"}) do
    options = [class: "bi", width: "14", height: "14", fill: "currentColor"]

    content_tag(:svg, options) do
      raw("<use xlink:href=\"/images/bootstrap-icons.svg#exclamation-triangle\"/>")
    end
  end

  defp pending_payment_alert(_), do: nil

  defp payment_kind(kind), do: @payment_kinds[kind]
end
