defmodule Tq2Web.PaymentLiveUtils do
  import Phoenix.LiveView,
    only: [
      assign: 3,
      push_event: 3,
      push_redirect: 2,
      put_flash: 3,
      redirect: 2
    ]

  import Tq2.Utils.Urls, only: [store_uri: 0]

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

  def check_for_paid_cart(%{assigns: %{cart: nil}} = socket), do: socket

  def check_for_paid_cart(%{assigns: %{cart: cart}} = socket) do
    case Cart.paid?(cart) do
      true -> socket |> get_or_create_order(cart)
      false -> socket |> check_for_pending_payments()
    end
  end

  defp check_for_pending_payments(
         %{assigns: %{cart: %{payments: [_ | _] = payments}, store: store}} = socket
       ) do
    pendings = payments |> Enum.filter(&(&1.status == "pending" && &1.external_id))

    case pendings do
      [] -> socket |> push_redirect(to: Routes.payment_path(socket, :index, store))
      _ -> socket
    end
  end

  defp check_for_pending_payments(socket), do: socket

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

  def create_tbk_payment(socket, store, cart) do
    cart
    |> get_tbk_pending_payment()
    |> maybe_create_tbk_payment(cart)
    |> open_tbk_modal_event(socket, store)
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

  defp get_tbk_pending_payment(cart) do
    cart |> Tq2.Payments.get_pending_payment_for_cart_and_kind("transbank")
  end

  defp maybe_create_tbk_payment(nil, cart) do
    attrs = %{status: "pending", kind: "transbank", amount: Cart.total(cart)}

    case Tq2.Payments.create_payment(cart, attrs) do
      {:ok, payment} ->
        payment

      {:error, %{errors: errors}} ->
        errors
        |> Enum.map(fn {_k, error} -> Tq2Web.ErrorHelpers.translate_error(error) end)
        |> Enum.join("<br>")
    end
  end

  defp maybe_create_tbk_payment(payment, _cart), do: payment

  defp open_tbk_modal_event(errors, socket, _store) when is_binary(errors) do
    socket |> put_flash(:error, errors)
  end

  defp open_tbk_modal_event(_payment, socket, store) do
    uri = store_uri()

    data = %{
      callbackUrl: Routes.payment_check_url(uri, :index, store),
      commerceLogo: Tq2.LogoUploader.url({store.logo, store}, :thumb),
      endpoint: Routes.transbank_payment_url(uri, :transbank, store),
      transactionDescription: store.name
    }

    socket |> push_event("openModal", data)
  end
end
