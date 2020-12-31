defmodule Tq2Web.Order.PaymentComponent do
  use Tq2Web, :live_component

  import Tq2Web.OrderView, only: [format_money: 1, payment_kind: 1]

  defp link_to_delete(conn, payment) do
    icon_link(
      conn,
      "backspace-reverse",
      to: "#",
      phx_click: "delete",
      phx_value_id: payment.id
    )
  end
end