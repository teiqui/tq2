defmodule Tq2Web.Store.PaymentLive do
  use Tq2Web, :live_view

  import Tq2Web.PaymentLiveUtils, only: [create_order: 3, check_for_paid_cart: 1]
  import Tq2Web.Store.ButtonComponent, only: [cart_total: 1]

  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential
  alias Tq2.Payments
  alias Tq2.Transactions.Cart
  alias Tq2.{Apps, Shops, Transactions}
  alias Tq2Web.Store.HeaderComponent

  @impl true
  def mount(%{"slug" => slug}, %{"token" => token}, socket) do
    store = Shops.get_store!(slug)
    payment_methods = available_payment_methods(store)

    socket =
      socket
      |> assign(store: store, token: token, payment_methods: payment_methods)
      |> load_cart(token)
      |> check_for_paid_cart()

    {:ok, socket, temporary_assigns: [cart: nil]}
  end

  @impl true
  def handle_event(
        "update",
        %{"kind" => kind},
        %{assigns: %{store: %{account: account}, token: token}} = socket
      ) do
    cart = Transactions.get_cart(account, token)
    data = (cart.data || %Tq2.Transactions.Data{}) |> Map.from_struct()

    case Transactions.update_cart(account, cart, %{data: %{data | payment: kind}}) do
      {:ok, cart} ->
        {:noreply, assign(socket, cart: cart)}

      {:error, %Ecto.Changeset{}} ->
        # TODO: handle this case properly
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "save",
        _params,
        %{assigns: %{store: %{account: account} = store, token: token}} = socket
      ) do
    cart = Transactions.get_cart(account, token)

    case cart.data.payment do
      "cash" ->
        socket = socket |> create_order(store, cart)

        {:noreply, socket}

      "mercado_pago" ->
        socket = socket |> create_mp_payment(store, cart)

        {:noreply, socket}
    end
  end

  defp load_cart(%{assigns: %{store: %{account: account}}} = socket, token) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end

  defp submit_payment(cart) do
    text = cart_total(cart)

    submit(text,
      class: "btn btn-lg btn-block btn-primary",
      disabled: !(cart.data && cart.data.payment),
      phx_disable_width: dgettext("payments", "Saving...")
    )
  end

  defp create_mp_payment(socket, store, cart) do
    cart
    |> create_mp_preference(store)
    |> create_pending_payment(cart)
    |> response_from_payment(socket)
  end

  defp available_payment_methods(store) do
    main_methods =
      if store.configuration.pickup || store.configuration.pay_on_delivery do
        [{"cash", dgettext("payments", "Cash")}]
      else
        []
      end

    app_names =
      store.account
      |> Apps.payment_apps()
      |> Enum.map(& &1.name)
      |> Enum.map(fn name -> {name, translate_name(name)} end)

    main_methods ++ app_names
  end

  defp payment_method_description("cash") do
    dgettext("payments", "Your order must be paid on delivery.")
  end

  defp payment_method_description("mercado_pago") do
    dgettext("payments", "Pay with MercadoPago.")
  end

  defp payment_method_description("wire_transfer") do
    dgettext("payments", "Pay with a wire transfer.")
  end

  defp static_img(kind, text) do
    img_tag(
      Routes.static_path(Tq2Web.Endpoint, "/images/#{kind}.png"),
      alt: text,
      width: "20",
      height: "20",
      class: "img-fluid rounded mr-3"
    )
  end

  defp cart_payment_kind?(cart, kind) do
    cart.data && cart.data.payment == kind
  end

  defp translate_name("mercado_pago") do
    dgettext("payments", "MercadoPago")
  end

  defp translate_name("wire_transfer") do
    dgettext("payments", "Wire transfer")
  end

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

  defp mp_cart_preference(payment, _, _), do: payment.gateway_data

  defp create_pending_payment(%{"message" => error}, _), do: error

  defp create_pending_payment(mp_preference, cart) do
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
