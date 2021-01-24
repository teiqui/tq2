defmodule Tq2Web.Order.PaymentComponent do
  use Tq2Web, :live_component

  import Tq2Web.OrderView, only: [format_money: 1, payment_kind: 1]

  defp link_to_delete(payment) do
    icon_link(
      "backspace-reverse",
      to: "#",
      phx_click: "delete",
      phx_value_id: payment.id,
      phx_target: "#payments-component"
    )
  end
end
