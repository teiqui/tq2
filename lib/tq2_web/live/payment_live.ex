defmodule Tq2Web.PaymentLive do
  use Tq2Web, :live_view

  import Tq2Web.ButtonComponent, only: [cart_total: 1]

  alias Tq2.{Apps, Sales, Shops, Transactions}
  alias Tq2Web.HeaderComponent

  @impl true
  def mount(%{"slug" => slug}, %{"token" => token}, socket) do
    store = Shops.get_store!(slug)
    payment_methods = available_payment_methods(store)

    socket =
      socket
      |> assign(store: store, token: token, payment_methods: payment_methods)
      |> load_cart(token)

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
        create_order(socket, store, cart)
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

  defp create_order(socket, store, cart) do
    sale_params = %{
      cart_id: cart.id,
      promotion_expires_at: Timex.now() |> Timex.shift(days: 1)
    }

    case Sales.create_order(store.account, sale_params) do
      {:ok, order} ->
        socket =
          socket
          |> push_redirect(to: Routes.order_path(socket, :index, store, order))

        {:noreply, socket}

      {:error, %Ecto.Changeset{}} ->
        # TODO: handle this case properly
        {:noreply, socket}
    end
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
end
