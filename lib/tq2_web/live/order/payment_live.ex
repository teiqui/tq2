defmodule Tq2Web.Order.PaymentLive do
  use Tq2Web, :live_view

  alias Tq2.Accounts
  alias Tq2.Payments
  alias Tq2.Sales
  alias Tq2.Transactions.Cart
  alias Tq2Web.Order.{PaymentComponent, PaymentFormComponent}

  @default_attrs %{
    "amount" => nil,
    "kind" => "cash",
    "status" => "paid"
  }
  @order_payment_methods ~w(cash other wire_transfer)

  @impl true
  def mount(_, %{"account_id" => account_id, "order_id" => id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)

    socket =
      socket
      |> assign(session: session)
      |> load_order(id)

    {:ok, socket}
  end

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> put_flash(:error, dgettext("sessions", "You must be logged in."))
      |> redirect(to: Routes.root_path(socket, :index))

    {:ok, socket}
  end

  @impl true
  def handle_event("update", %{"payment" => attrs}, %{assigns: %{cart: cart}} = socket) do
    changeset = cart |> payment_changeset(attrs)
    socket = socket |> assign(changeset: changeset)

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "save",
        %{"payment" => attrs},
        %{assigns: %{cart: cart, session: session}} = socket
      ) do
    attrs = attrs |> Enum.into(@default_attrs)

    session
    |> Payments.create_payment(cart, attrs)
    |> create_payment_response(socket)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, %{assigns: %{payments: payments}} = socket) do
    socket =
      payments
      |> Enum.find(&("#{&1.id}" == id))
      |> delete_payment_response(socket)

    {:noreply, socket}
  end

  defp load_order(%{assigns: %{session: %{account: account}}} = socket, id) do
    order = Sales.get_order!(account, id)

    socket =
      socket
      |> assign(order: order, cart: %{order.cart | account: account})

    order.cart.payments
    |> Enum.filter(&(&1.status == "paid"))
    |> assign_payments(socket)
  end

  defp payment_changeset(cart) do
    Payments.change_payment(cart, payment_attrs(cart))
  end

  defp payment_changeset(cart, attrs) do
    attrs = Enum.into(attrs, @default_attrs)

    Payments.change_payment(cart, attrs)
  end

  defp payment_attrs(cart) do
    attrs = %{@default_attrs | "amount" => Cart.pending_amount(cart)}

    case cart.data && cart.data.payment do
      k when k in @order_payment_methods -> %{attrs | "kind" => k}
      _ -> attrs
    end
  end

  defp need_payments?(cart, payments) do
    !Cart.paid_in_full?(payments, cart)
  end

  defp delete_payment_response(nil, socket), do: socket

  defp delete_payment_response(
         payment,
         %{assigns: %{payments: payments, session: session}} = socket
       ) do
    case Payments.delete_payment(session, payment) do
      {:ok, payment} ->
        payments
        |> Enum.reject(&(&1.id == payment.id))
        |> assign_payments(socket)

      {:error, _changeset} ->
        # TODO: handle this case properly
        socket
    end
  end

  defp create_payment_response(
         {:ok, payment},
         %{assigns: %{cart: cart, payments: payments}} = socket
       ) do
    payments = payments ++ [payment]
    socket = assign_payments(payments, socket)

    socket =
      case Cart.paid_in_full?(payments, cart) do
        true -> pay_order(socket)
        _ -> socket
      end

    {:noreply, socket}
  end

  defp create_payment_response({:error, changeset}, socket) do
    socket = socket |> assign(changeset: changeset)

    {:noreply, socket}
  end

  defp assign_payments(payments, %{assigns: %{cart: cart}} = socket) do
    changeset =
      %{cart | payments: payments}
      |> payment_changeset()

    assign(socket, payments: payments, changeset: changeset)
  end

  defp pay_order(%{assigns: %{order: order, session: session}} = socket) do
    data =
      case order.data do
        nil -> %{paid: true}
        data -> data |> Map.from_struct() |> Map.put(:paid, true)
      end

    case Sales.update_order(session, order, %{data: data}) do
      {:ok, _order} -> socket
      # TODO: handle this case properly
      {:error, _changeset} -> socket
    end
  end
end
