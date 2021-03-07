defmodule Tq2Web.Store.PaymentLive do
  use Tq2Web, :live_view

  import Tq2Web.PaymentLiveUtils,
    only: [
      available_payment_methods_for_store: 1,
      cart_payment_kind?: 2,
      check_for_paid_cart: 1,
      create_payment_or_go_to_order: 3,
      maybe_put_phx_hook: 1
    ]

  alias Tq2.Transactions
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
    socket = socket |> create_payment_or_go_to_order(store, cart)

    {:noreply, socket}
  end

  defp finish_mount(%{assigns: %{cart: nil, store: store}} = socket) do
    socket =
      socket
      |> push_redirect(to: Routes.counter_path(socket, :index, store))

    {:ok, socket}
  end

  defp finish_mount(%{assigns: %{store: store}} = socket) do
    socket = socket |> assign(:payment_methods, available_payment_methods_for_store(store))

    {:ok, socket, temporary_assigns: [cart: nil]}
  end

  defp load_cart(%{assigns: %{store: %{account: account}, token: token}} = socket) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
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
    dgettext("payments", "Pay with Onepay app.")
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
end
