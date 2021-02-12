defmodule Tq2Web.Order.PaymentsComponent do
  use Tq2Web, :live_component

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
  def update(%{id: id, order: %{cart: cart} = order, session: session}, socket) do
    socket =
      socket
      |> assign(cart: cart, id: id, order: order, session: session)
      |> filter_payments()

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

  defp filter_payments(%{assigns: %{cart: %{payments: []}}} = socket) do
    assign_payments([], socket)
  end

  defp filter_payments(%{assigns: %{cart: %{payments: payments}}} = socket) do
    payments
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
        |> update_order_paid()

      {:error, _changeset} ->
        # TODO: handle this case properly
        socket
    end
  end

  defp create_payment_response(
         {:ok, payment},
         %{assigns: %{cart: cart, order: order, payments: payments}} = socket
       ) do
    payments = payments ++ [payment]
    socket = assign_payments(payments, socket)

    socket =
      case Cart.paid_in_full?(payments, cart) do
        true ->
          update_order_paid(socket)

        _ ->
          order |> refresh_order(payments)

          socket
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

  defp update_order_paid(
         %{assigns: %{order: order, payments: payments, session: session}} = socket
       ) do
    paid? = payments |> Cart.paid_in_full?(order.cart)

    data =
      case order.data do
        nil -> %{paid: paid?}
        data -> data |> Map.from_struct() |> Map.put(:paid, paid?)
      end

    case Sales.update_order(session, order, %{data: data}) do
      {:ok, order} ->
        order |> refresh_order(payments)

        socket

      # TODO: handle this case properly
      {:error, _changeset} ->
        socket
    end
  end

  defp refresh_order(order, payments) do
    send(self(), {:refresh_order, %{order: order, payments: payments}})
  end
end
