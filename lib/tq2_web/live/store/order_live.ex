defmodule Tq2Web.Store.OrderLive do
  use Tq2Web, :live_view

  alias Tq2.{Analytics, Sales}
  alias Tq2Web.Store.{HeaderComponent, ShareComponent}

  @impl true
  def mount(%{"id" => id}, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    visit = Analytics.get_visit!(visit_id)

    socket =
      socket
      |> assign(
        store: store,
        token: token,
        visit_id: visit_id,
        referral_customer: visit.referral_customer
      )
      |> load_order(id)

    {:ok, socket, temporary_assigns: [order: nil, cart: nil, referral_customer: nil]}
  end

  defp load_order(%{assigns: %{store: %{account: account}}} = socket, id) do
    order = Sales.get_order!(account, id)

    assign(socket, order: order, cart: order.cart)
  end

  defp share_classes do
    "btn btn-primary rounded-pill py-2 px-4"
  end

  defp show_payment_info(socket, %{cart: %{data: %{payment: "wire_transfer"}}}, account) do
    app = Tq2.Apps.get_app(account, "wire_transfer")

    title =
      content_tag(:div, class: "text-center") do
        content_tag(:b, dgettext("orders", "Don't forget to make the payment!"))
      end

    number =
      content_tag(:p) do
        [
          app.data.account_number,
          link_to_clipboard(
            socket,
            icon: "files",
            text: app.data.account_number,
            class: "ml-2"
          )
        ]
      end

    [
      tag(:hr, class: "my-4"),
      title,
      content_tag(:p, dgettext("payments", "Wire transfer")),
      content_tag(:p, app.data.description),
      number
    ]
  end

  defp show_payment_info(_socket, _order, _account), do: nil
end
