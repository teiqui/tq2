defmodule Tq2Web.PaymentLiveUtils do
  import Phoenix.LiveView, only: [push_redirect: 2, redirect: 2, assign: 3]

  alias Tq2.{Apps, Payments}
  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential
  alias Tq2.Payments.Payment
  alias Tq2.Sales
  alias Tq2.Transactions.Cart
  alias Tq2Web.Router.Helpers, as: Routes

  def get_or_create_order(socket, cart) do
    cart = Tq2.Repo.preload(cart, :order)
    store = socket.assigns.store

    case cart.order do
      nil -> create_order(socket, store, cart)
      order -> socket |> push_redirect(to: Routes.order_path(socket, :index, store, order))
    end
  end

  def create_order(socket, store, cart) do
    attrs = order_attrs(store.account, cart)

    case Sales.create_order(store.account, attrs) do
      {:ok, order} ->
        socket |> push_redirect(to: Routes.order_path(socket, :index, store, order))

      {:error, %Ecto.Changeset{}} ->
        # TODO: handle this case properly
        socket
    end
  end

  def check_for_paid_cart(%{assigns: %{cart: cart}} = socket) do
    case Cart.paid?(cart) do
      true -> get_or_create_order(socket, cart)
      false -> socket
    end
  end

  defp order_attrs(account, cart) do
    cart
    |> initial_order_attrs()
    |> build_order_tie(account, cart)
    |> mark_order_as_paid(cart)
  end

  def initial_order_attrs(%Cart{id: id}) do
    %{
      cart_id: id,
      promotion_expires_at: Timex.now() |> Timex.shift(days: 1),
      data: %{}
    }
  end

  def create_mp_payment(socket, store, cart) do
    cart
    |> create_mp_preference(store)
    |> handle_pending_payment(cart)
    |> response_from_payment(socket)
  end

  defp build_order_tie(attrs, account, cart) do
    visit = Tq2.Analytics.get_visit!(cart.visit_id)

    case visit.referral_customer do
      nil -> attrs
      customer -> Map.put(attrs, :ties, build_order_tie(account, customer))
    end
  end

  defp build_order_tie(account, customer) do
    case Tq2.Sales.get_promotional_order_for(account, customer) do
      nil -> []
      order -> [%{originator_id: order.id}]
    end
  end

  defp mark_order_as_paid(attrs, %Cart{payments: %Ecto.Association.NotLoaded{}}), do: attrs
  defp mark_order_as_paid(attrs, %Cart{payments: []}), do: attrs
  defp mark_order_as_paid(attrs, cart), do: %{attrs | data: %{paid: Cart.paid?(cart)}}

  defp create_mp_preference(cart, store) do
    cart = Tq2.Repo.preload(cart, :payments)

    cart.payments
    |> Enum.find(&(&1.status == "pending" && &1.kind == "mercado_pago" && &1.gateway_data))
    |> mp_cart_preference(cart, store)
  end

  defp mp_cart_preference(nil, cart, store) do
    store.account
    |> Apps.get_app("mercado_pago")
    |> MPCredential.for_app()
    |> MPClient.create_cart_preference(cart, store)
  end

  defp mp_cart_preference(payment, _, _), do: payment

  defp handle_pending_payment(%{"message" => error}, _), do: error

  defp handle_pending_payment(%Payment{} = payment, _cart) do
    {:ok, payment}
  end

  defp handle_pending_payment(mp_preference, cart) do
    attrs = %{
      status: "pending",
      kind: "mercado_pago",
      amount: Cart.total(cart),
      external_id: mp_preference["external_reference"],
      gateway_data: mp_preference
    }

    cart |> Payments.create_payment(attrs)
  end

  defp response_from_payment({:error, _payment_cs}, socket) do
    # TODO: handle this case properly
    socket
  end

  defp response_from_payment({:ok, payment}, socket) do
    socket =
      socket
      |> redirect(external: payment.gateway_data["init_point"])

    socket
  end

  defp response_from_payment(error_msg, socket) do
    socket |> assign(:alert, error_msg)
  end
end
