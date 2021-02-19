defmodule Tq2Web.Store.PaymentCheckLive do
  use Tq2Web, :live_view

  import Tq2Web.PaymentLiveUtils, only: [check_for_paid_cart: 1]

  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential
  alias Tq2.Gateways.Transbank, as: TbkClient
  alias Tq2.Payments
  alias Tq2.Payments.Payment
  alias Tq2.{Apps, Transactions}
  alias Tq2Web.Store.HeaderComponent

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    socket
    |> assign(store: store, token: token, visit_id: visit_id)
    |> load_cart()
    |> check_payments()
    |> finish_mount()
  end

  @impl true
  def handle_info({:timer}, socket) do
    socket = socket |> check_payments()

    {:noreply, socket}
  end

  defp finish_mount(%{assigns: %{cart: nil, store: store}} = socket) do
    socket =
      socket
      |> push_redirect(to: Routes.counter_path(socket, :index, store))

    {:ok, socket}
  end

  defp finish_mount(socket), do: {:ok, socket}

  defp load_cart(%{assigns: %{store: %{account: account}, token: token}} = socket) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end

  defp check_payments(%{assigns: %{cart: nil}} = socket), do: socket

  defp check_payments(%{assigns: %{cart: cart, store: store}} = socket) do
    cart = Tq2.Repo.preload(cart, :payments)

    case cart.payments do
      [] ->
        socket |> push_redirect(to: Routes.payment_path(socket, :index, store))

      payments ->
        socket = check_pending_payments(payments, store.account, socket)

        cart = Tq2.Repo.preload(cart, :payments, force: true)

        self() |> Process.send_after({:timer}, 5000)

        socket
        |> assign(cart: cart)
        |> check_for_paid_cart()
    end
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
end
