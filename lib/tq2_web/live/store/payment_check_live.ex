defmodule Tq2Web.Store.PaymentCheckLive do
  use Tq2Web, :live_view

  import Tq2Web.PaymentLiveUtils, only: [check_for_paid_cart: 1]

  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential
  alias Tq2.Payments
  alias Tq2.Payments.Payment
  alias Tq2.{Apps, Shops, Transactions}
  alias Tq2Web.Store.HeaderComponent

  @impl true
  def mount(%{"slug" => slug}, %{"token" => token}, socket) do
    store = Shops.get_store!(slug)
    cart = Transactions.get_cart(store.account, token)

    socket =
      socket
      |> assign(store: store, cart: cart)
      |> check_payments()

    self() |> Process.send_after({:timer}, 5000)

    {:ok, socket}
  end

  @impl true
  def handle_info({:timer}, socket) do
    socket = socket |> check_payments()

    self() |> Process.send_after({:timer}, 5000)

    {:noreply, socket}
  end

  defp check_payments(socket) do
    store = socket.assigns.store
    cart = Tq2.Repo.preload(socket.assigns.cart, :payments)

    case cart.payments do
      [] ->
        socket |> push_redirect(to: Routes.payment_path(socket, :index, store))

      payments ->
        check_pending_payments(payments, store.account)

        cart = Tq2.Repo.preload(cart, :payments, force: true)

        socket
        |> assign(cart: cart)
        |> check_for_paid_cart()
    end
  end

  defp check_pending_payments(payments, account) do
    payments
    |> Enum.filter(&(&1.status == "pending" && &1.external_id))
    |> Enum.each(&check_payment(&1, account))
  end

  defp check_payment(%Payment{kind: "mercado_pago"} = payment, account) do
    account
    |> Apps.get_app("mercado_pago")
    |> MPCredential.for_app()
    |> MPClient.get_payment(payment.gateway_data["id"])
    |> MPClient.response_to_payment()
    |> Payments.update_payment(account)
  end
end
