defmodule Tq2Web.Store.OrderLive do
  use Tq2Web, :live_view

  import Tq2Web.Utils, only: [format_money: 1]

  import Tq2Web.PaymentLiveUtils,
    only: [
      available_payment_methods_for_store: 1,
      cart_payment_kind?: 2,
      check_payments_with_timer: 1,
      create_payment_or_go_to_order: 3,
      maybe_put_phx_hook: 1,
      translate_kind: 1
    ]

  alias Tq2.{Analytics, Sales}
  alias Tq2.Transactions.Cart
  alias Tq2Web.Order.CommentsComponent
  alias Tq2Web.Store.{HeaderComponent, NotificationComponent, ShareComponent}

  @gateway_kinds ~w[conekta mercado_pago transbank]

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
      |> load_payment_methods()

    {:ok, socket, temporary_assigns: [error: nil, referral_customer: nil]}
  end

  @impl true
  def handle_params(%{"externalUniqueNumber" => _}, _uri, socket) do
    # Transbank
    socket = socket |> check_payments_with_timer()

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"external_reference" => _}, _uri, socket) do
    # MercadoPago
    socket = socket |> check_payments_with_timer()

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"checkout_id" => _}, _uri, socket) do
    # Conekta
    socket = socket |> check_payments_with_timer()

    {:noreply, socket}
  end

  @impl true
  def handle_params(%{"status" => _}, _uri, socket) do
    socket = socket |> assign(:status, true)

    {:noreply, socket}
  end

  @impl true
  def handle_params(_params, _uri, socket), do: {:noreply, socket}

  @impl true
  def handle_event("pay", _, %{assigns: %{cart: cart, store: store}} = socket) do
    socket = socket |> create_payment_or_go_to_order(store, cart)

    {:noreply, socket}
  end

  @impl true
  def handle_event("show-payment-methods", _, socket) do
    socket = socket |> assign(:show_payment_methods, true)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "save-payment",
        %{"kind" => kind},
        %{assigns: %{cart: cart, store: %{account: account}}} = socket
      ) do
    data =
      cart.data
      |> Tq2.Transactions.Data.from_struct()
      |> Map.put(:payment, kind)

    case Tq2.Transactions.update_cart(account, cart, %{data: data}) do
      {:ok, _cart} ->
        data = %{cart.data | payment: kind}
        cart = %{cart | data: data}
        socket = socket |> assign(cart: cart, show_payment_methods: false)

        {:noreply, socket}

      {:error, %Ecto.Changeset{errors: errors}} ->
        Sentry.capture_message(
          "[Order payment change] Cart can't be updated",
          extra: %{errors: inspect(errors)}
        )

        {:noreply, socket}
    end
  end

  @impl true
  def handle_info({:timer}, socket) do
    socket = socket |> check_payments_with_timer()

    {:noreply, socket}
  end

  @impl true
  def handle_info({:comment_created, comment}, socket) do
    send_update(CommentsComponent, id: :comments, comment: comment)

    {:noreply, socket}
  end

  defp load_order(%{assigns: %{store: %{account: account}}} = socket, id) do
    order = Sales.get_order!(account, id)
    cart = %{order.cart | order: order}

    assign(socket, order: order, cart: cart)
  end

  defp show_payment_info(
         %{
           cart: %{data: %{payment: "wire_transfer"}} = cart,
           order: order,
           show_payment_methods: show?,
           store: %{account: account}
         } = assigns
       ) do
    hr = tag(:hr, class: "my-4")

    cond do
      paid?(cart) ->
        nil

      show? ->
        complete_payment_info(assigns)

      expired_promo?(order) ->
        [
          complete_payment_info(assigns),
          hr,
          wire_transfer_info(account)
        ]

      true ->
        [hr, wire_transfer_info(account)]
    end
  end

  defp show_payment_info(%{cart: %{data: %{payment: kind}} = cart} = assigns)
       when kind in @gateway_kinds do
    case paid?(cart) do
      true -> nil
      false -> complete_payment_info(assigns)
    end
  end

  defp show_payment_info(_assigns), do: nil

  defp phx_hook_for_kind("transbank"), do: [phx_hook: "TransbankModal"]
  defp phx_hook_for_kind(_), do: []

  defp link_to_pay_in_gateway(kind) when kind in @gateway_kinds do
    translated_kind = translate_kind(kind)

    args =
      phx_hook_for_kind(kind) ++
        [
          to: "#",
          phx_click: "pay",
          id: "pay-with-#{kind}",
          class: "btn btn-primary font-weight-bold"
        ]

    content_tag(:p, class: "text-center mt-3") do
      link(dgettext("orders", "Pay with %{kind}", kind: translated_kind), args)
    end
  end

  defp link_to_pay_in_gateway(_kind), do: nil

  defp show_share_modal?(%{price_type: "promotional", referred: false}, %{status: _}), do: false
  defp show_share_modal?(%{price_type: "promotional", referred: false}, _assigns), do: true
  defp show_share_modal?(_cart, _assigns), do: false

  defp expired_promo?(%{cart: %{price_type: "regular"}, promotion_expires_at: expires_at}) do
    DateTime.compare(expires_at, DateTime.utc_now()) == :lt
  end

  defp expired_promo?(_order), do: false

  defp paid?(%{data: %{payment: "cash"}}), do: true
  defp paid?(cart), do: Tq2.Transactions.Cart.paid?(cart)

  defp complete_payment_description do
    content_tag(
      :p,
      dgettext(
        "orders",
        "Complete the payment of the purchase at regular price to receive your order. We kept your original payment method, you can change it."
      ),
      class: "mb-4"
    )
  end

  defp pending_price(cart) do
    pending_amount = cart |> Cart.pending_amount() |> format_money()

    content_tag(:div, class: "text-center") do
      content_tag(:p, dgettext("orders", "Total pending: %{price}", price: pending_amount),
        class: "mb-n1 font-weight-bold"
      )
    end
  end

  defp complete_payment_info(%{cart: cart} = assigns) do
    [
      tag(:hr, class: "my-4"),
      show_error(assigns),
      complete_payment_description(),
      pending_price(cart),
      pay_button(assigns),
      render_change_payment_method(assigns),
      render_payment_methods(assigns)
    ]
    |> Enum.filter(& &1)
  end

  defp wire_transfer_info(account) do
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
            icon: "files",
            text: app.data.account_number,
            class: "ml-2"
          )
        ]
      end

    [
      title,
      content_tag(:p, dgettext("payments", "Wire transfer")),
      content_tag(:p, app.data.description),
      number
    ]
  end

  defp load_payment_methods(%{assigns: %{store: store}} = socket) do
    socket
    |> assign(
      payment_methods: available_payment_methods_for_store(store),
      show_payment_methods: false
    )
  end

  defp render_payment_methods(%{show_payment_methods: false}), do: nil

  defp render_payment_methods(assigns) do
    ~E"""
    <form id="payment" phx-submit="save-payment">
      <%= for {kind, text, _} <- @payment_methods do %>
        <div class="custom-control custom-radio mt-3">
          <input type="radio"
                 id="<%= kind %>"
                 name="kind"
                 class="custom-control-input"
                 value="<%= kind %>"
                 <%= maybe_put_phx_hook kind %>
                 <%= if cart_payment_kind?(@cart, kind), do: "checked" %>>
          <label class="custom-control-label" for="<%= kind %>">
            <span class="ml-2 d-block">
              <%= static_img kind, text %>

              <span class="font-weight-semi-bold">
                <%= text %>
              </span>
            </span>
          </label>
        </div>
      <% end %>

      <%= submit_button() %>
    </form>
    """
  end

  defp static_img(kind, text) do
    img_tag(
      Routes.static_path(Tq2Web.Endpoint, "/images/#{kind}.png"),
      alt: text,
      width: "15",
      height: "15",
      class: "img-fluid rounded mr-3"
    )
  end

  defp submit_button do
    submit(
      dgettext("orders", "Change"),
      class: "btn btn-primary font-weight-bold float-right"
    )
  end

  defp pay_button(%{checking_payments: true}) do
    content_tag(:div, class: "text-center") do
      content_tag(:div, class: "spinner-border text-primary mt-3") do
        content_tag(:span, class: "sr-only") do
          dgettext("stores", "Loading...")
        end
      end
    end
  end

  defp pay_button(%{cart: %{data: %{payment: kind}}, show_payment_methods: false}) do
    link_to_pay_in_gateway(kind)
  end

  defp pay_button(_assigns), do: nil

  defp render_change_payment_method(%{payment_methods: [_, _ | _], show_payment_methods: false}) do
    # More than 1 method
    content_tag(:p, class: "mt-3 text-center") do
      link(
        dgettext("orders", "Change payment method"),
        to: "#",
        phx_click: "show-payment-methods"
      )
    end
  end

  defp render_change_payment_method(_assigns), do: nil

  defp show_error(%{error: error}) do
    content_tag(:div, error, class: "alert alert-danger text-center rounded-pill")
  end

  defp show_error(_assigns), do: nil
end
