defmodule Tq2Web.Store.PaymentLive do
  use Tq2Web, :live_view

  import Tq2Web.PaymentLiveUtils,
    only: [
      check_for_paid_cart: 1,
      create_mp_payment: 3,
      create_tbk_payment: 3,
      create_order: 3
    ]

  alias Tq2.{Apps, Transactions}
  alias Tq2Web.Store.{ButtonComponent, HeaderComponent, ProgressComponent}

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    socket
    |> assign(store: store, token: token, visit_id: visit_id)
    |> load_cart()
    |> check_for_paid_cart()
    |> finish_mount()
  end

  @impl true
  def handle_event(
        "update",
        %{"kind" => kind},
        %{assigns: %{store: %{account: account}, token: token}} = socket
      ) do
    cart = Transactions.get_cart(account, token)
    data = Tq2.Transactions.Data.from_struct(cart.data)

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
      "mercado_pago" ->
        socket = socket |> create_mp_payment(store, cart)

        {:noreply, socket}

      "transbank" ->
        socket = socket |> create_tbk_payment(store, cart)

        {:noreply, socket}

      _ ->
        socket = socket |> create_order(store, cart)

        {:noreply, socket}
    end
  end

  defp finish_mount(%{assigns: %{cart: nil, store: store}} = socket) do
    socket =
      socket
      |> push_redirect(to: Routes.counter_path(socket, :index, store))

    {:ok, socket}
  end

  defp finish_mount(%{assigns: %{store: store}} = socket) do
    socket = socket |> assign(:payment_methods, available_payment_methods(store))

    {:ok, socket, temporary_assigns: [cart: nil]}
  end

  defp load_cart(%{assigns: %{store: %{account: account}, token: token}} = socket) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end

  defp available_payment_methods(store) do
    main_methods =
      if store.configuration.pickup || store.configuration.pay_on_delivery do
        [{"cash", dgettext("payments", "Cash"), nil}]
      else
        []
      end

    # TODO: Remove this ones Transbank app is implemented
    main_methods =
      if Application.get_env(:tq2, :env) == :prod do
        main_methods
      else
        main_methods ++
          [{"transbank", translate_name("transbank"), %Tq2.Apps.App{name: "transbank"}}]
      end

    app_names =
      store.account
      |> Apps.payment_apps()
      |> Enum.map(&{&1.name, &1})
      |> Enum.map(fn {name, app} -> {name, translate_name(name), app} end)

    main_methods ++ app_names
  end

  defp payment_method_description("cash", _) do
    dgettext("payments", "Your order must be paid on delivery.")
  end

  defp payment_method_description("mercado_pago", _) do
    dgettext("payments", "Pay with MercadoPago.")
  end

  defp payment_method_description("wire_transfer", app) do
    number =
      content_tag(:p) do
        [
          app.data["account_number"],
          link_to_clipboard(
            icon: "files",
            text: app.data["account_number"],
            class: "ml-2"
          )
        ]
      end

    [content_tag(:p, app.data["description"]), number]
  end

  defp payment_method_description("transbank", _) do
    dgettext("payments", "Pay with OnePay app.")
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

  defp translate_name("transbank") do
    dgettext("payments", "Transbank - OnePay")
  end

  defp maybe_put_phx_hook("transbank"), do: "phx-hook=TransbankModal"
  defp maybe_put_phx_hook(_), do: nil
end
