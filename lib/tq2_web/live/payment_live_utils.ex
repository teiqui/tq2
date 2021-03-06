defmodule Tq2Web.PaymentLiveUtils do
  import Phoenix.LiveView,
    only: [
      assign: 2,
      assign: 3,
      push_event: 3,
      push_redirect: 2,
      put_flash: 3,
      redirect: 2
    ]

  import Tq2Web.Gettext, only: [dgettext: 2]
  import Tq2.Utils.Urls, only: [store_uri: 0]

  alias Tq2.{Apps, Payments}
  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential
  alias Tq2.Gateways.Transbank, as: TbkClient
  alias Tq2.Payments.Payment
  alias Tq2.Sales
  alias Tq2.Transactions.Cart
  alias Tq2Web.Router.Helpers, as: Routes

  def translate_kind("cash"), do: dgettext("payments", "Cash")
  def translate_kind("mercado_pago"), do: dgettext("payments", "MercadoPago")
  def translate_kind("transbank"), do: dgettext("payments", "Transbank - Onepay")
  def translate_kind("wire_transfer"), do: dgettext("payments", "Wire transfer")

  def cart_payment_kind?(%Cart{data: %{payment: kind}}, kind), do: true
  def cart_payment_kind?(_cart, _kind), do: false

  def available_payment_methods_for_store(store) do
    main_methods =
      if store.configuration.pickup || store.configuration.pay_on_delivery do
        [{"cash", dgettext("payments", "Cash"), nil}]
      else
        []
      end

    app_names =
      store.account
      |> Apps.payment_apps()
      |> Enum.map(&{&1.name, &1})
      |> Enum.map(fn {name, app} -> {name, translate_kind(name), app} end)

    main_methods ++ app_names
  end

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

  def create_payment_or_go_to_order(socket, store, cart) do
    cart = Tq2.Repo.preload(cart, :order)

    case cart.data.payment do
      "mercado_pago" -> socket |> create_mp_payment(store, cart)
      "transbank" -> socket |> create_tbk_payment(store, cart)
      _ -> socket |> get_or_create_order(cart)
    end
  end

  def check_for_paid_cart(%{assigns: %{cart: nil}} = socket), do: socket

  def check_for_paid_cart(%{assigns: %{cart: cart}} = socket) do
    case Cart.paid?(cart) do
      true -> socket |> get_or_create_order(cart)
      false -> socket |> check_for_pending_payments_or_redirect()
    end
  end

  def check_payments_with_timer(%{assigns: %{cart: nil}} = socket), do: socket

  def check_payments_with_timer(%{assigns: %{cart: cart, store: store}} = socket) do
    cart = Tq2.Repo.preload(cart, :payments)

    case cart.payments do
      [] ->
        socket |> push_redirect(to: Routes.payment_path(socket, :index, store))

      payments ->
        socket = check_pending_payments(payments, store.account, socket)
        cart = Tq2.Repo.preload(cart, :payments, force: true)

        self() |> Process.send_after({:timer}, 5000)

        socket
        |> assign(cart: cart, checking_payments: true)
        |> check_for_paid_cart()
    end
  end

  defp check_for_pending_payments_or_redirect(
         %{assigns: %{cart: %{payments: [_ | _] = payments}}} = socket
       ) do
    pendings = payments |> Enum.filter(&(&1.status == "pending" && &1.external_id))

    case pendings do
      [] -> socket |> push_redirect(to: redirect_path_without_pending_payments(socket))
      _ -> socket
    end
  end

  defp check_for_pending_payments_or_redirect(socket), do: socket

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
    |> open_tbk_modal_event(socket, store, cart)
  end

  def maybe_put_phx_hook("transbank"), do: "phx-hook=TransbankModal"
  def maybe_put_phx_hook(_), do: nil

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
    |> partial_or_full_preference(cart, store)
  end

  defp mp_cart_preference(payment, _, _), do: payment

  defp partial_or_full_preference(%MPCredential{} = cred, cart, store) do
    partial = cart.payments |> Enum.any?(fn p -> p.status == "paid" end)

    case partial do
      false -> MPClient.create_cart_preference(cred, cart, store)
      true -> MPClient.create_partial_cart_preference(cred, cart, store)
    end
  end

  defp handle_pending_payment(%{"message" => error}, _), do: error

  defp handle_pending_payment(%Payment{} = payment, _cart) do
    {:ok, payment}
  end

  defp handle_pending_payment(mp_preference, cart) do
    attrs = %{
      status: "pending",
      kind: "mercado_pago",
      amount: Cart.pending_amount(cart),
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
    attrs = %{status: "pending", kind: "transbank", amount: Cart.pending_amount(cart)}

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

  defp open_tbk_modal_event(errors, socket, _store, _order) when is_binary(errors) do
    socket |> put_flash(:error, errors)
  end

  defp open_tbk_modal_event(_payment, socket, store, %{order: nil} = cart) do
    uri = store_uri()
    image = socket |> store_image(store)

    data = %{
      callbackUrl: Routes.payment_check_url(uri, :index, store),
      commerceLogo: image,
      endpoint: Routes.transbank_payment_url(uri, :transbank, store, id: cart.id),
      transactionDescription: store.name
    }

    socket |> push_event("openModal", data)
  end

  defp open_tbk_modal_event(_payment, socket, store, cart) do
    uri = store_uri()
    image = socket |> store_image(store)

    data = %{
      callbackUrl: Routes.order_url(uri, :index, store, cart.order),
      commerceLogo: image,
      endpoint: Routes.transbank_payment_url(uri, :transbank, store, id: cart.id),
      transactionDescription: store.name
    }

    socket |> push_event("openModal", data)
  end

  defp check_pending_payments(payments, account, socket) do
    payments
    |> Enum.filter(&(&1.status == "pending" && &1.external_id))
    |> Enum.map(&check_payment(&1, account))
    |> Enum.find(&is_binary(&1))
    |> maybe_add_error_flash(socket)
  end

  defp check_payment(%Payment{kind: "mercado_pago"} = payment, account) do
    account
    |> Apps.get_app("mercado_pago")
    |> MPCredential.for_app()
    |> MPClient.get_payment(payment.gateway_data["id"])
    |> MPClient.response_to_payment()
    |> Payments.update_payment_by_external_id(account)

    nil
  end

  defp check_payment(%Payment{kind: "transbank"} = payment, account) do
    response =
      account
      |> Apps.get_app("transbank")
      |> TbkClient.confirm_preference(payment)
      |> TbkClient.response_to_payment(payment)

    response
    |> Payments.update_payment_by_external_id(account)
    |> process_payment_update()
    |> maybe_append_error_description(response)
  end

  defp maybe_append_error_description(nil, %{error: error}), do: error

  defp maybe_append_error_description(errors, %{error: error}) when is_binary(errors) do
    "#{errors}<br>#{error}"
  end

  defp maybe_append_error_description(_, _), do: nil

  defp process_payment_update({:ok, _}), do: nil

  defp process_payment_update({:error, %{errors: errors}}) do
    errors
    |> Enum.map(fn {_k, error} -> Tq2Web.ErrorHelpers.translate_error(error) end)
    |> Enum.join("<br>")
  end

  defp maybe_add_error_flash(error, socket) when is_binary(error) do
    socket |> put_flash(:error, error)
  end

  defp maybe_add_error_flash(_, socket), do: socket

  defp redirect_path_without_pending_payments(%{assigns: %{order: order, store: store}} = socket) do
    Routes.order_path(socket, :index, store, order)
  end

  defp redirect_path_without_pending_payments(%{assigns: %{store: store}} = socket) do
    Routes.payment_path(socket, :index, store)
  end

  defp store_image(socket, %{logo: nil}) do
    socket |> Routes.static_url("/images/store_default_logo.svg")
  end

  defp store_image(_socket, store) do
    Tq2.LogoUploader.url({store.logo, store}, :thumb_2x)
  end
end
