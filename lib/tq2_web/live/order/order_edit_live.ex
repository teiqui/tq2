defmodule Tq2Web.Order.OrderEditLive do
  use Tq2Web, :live_view

  import Tq2Web.Utils.Cart, only: [cart_promotional_total: 1, cart_regular_total: 1]

  alias Tq2.Sales
  alias Tq2.Transactions.Cart
  alias Tq2Web.Order.PaymentsComponent

  @statuses %{
    dgettext("orders", "Pending") => "pending",
    dgettext("orders", "Processing") => "processing",
    dgettext("orders", "Completed") => "completed",
    dgettext("orders", "Canceled") => "canceled"
  }

  @impl true
  def mount(%{"id" => id}, %{"current_session" => %{} = session}, socket) do
    socket =
      socket
      |> assign(session: session)
      |> load_order(id)
      |> add_changeset()

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
  def handle_event("save", %{"order" => attrs} = params, socket) do
    socket =
      socket
      |> update_cart_if_needed(params)
      |> update_order(attrs)

    {:noreply, socket}
  end

  @impl true
  def handle_info(
        {:refresh_order, %{order: order, payments: payments}},
        %{assigns: %{cart: cart, order: old_order}} = socket
      ) do
    cart = %{cart | payments: payments}
    order = %{order | cart: cart, customer: old_order.customer}

    socket =
      socket
      |> assign(order: order)
      |> add_changeset()

    {:noreply, socket}
  end

  defp load_order(%{assigns: %{session: %{account: account}}} = socket, id) do
    order = Sales.get_order!(account, id)
    cart = %{order.cart | account: account}

    socket |> assign(cart: cart, order: order)
  end

  defp add_changeset(%{assigns: %{order: order, session: %{account: account}}} = socket) do
    changeset = account |> Sales.change_order(order)

    socket |> assign(:changeset, changeset)
  end

  defp statuses, do: @statuses

  defp submit_button do
    dgettext("orders", "Update")
    |> submit(class: "btn btn-primary rounded-pill font-weight-bold py-2")
  end

  defp lock_version_input(form, order) do
    hidden_input(form, :lock_version, value: order.lock_version)
  end

  defp update_order(%{assigns: %{order: order, session: session}} = socket, attrs) do
    attrs = order_attrs(socket, attrs)

    case Sales.update_order(session, order, attrs) do
      {:ok, order} ->
        socket
        |> put_flash(:info, dgettext("orders", "Order updated successfully."))
        |> redirect(to: Routes.order_path(socket, :show, order))

      {:error, %Ecto.Changeset{} = changeset} ->
        socket |> assign(changeset: changeset)
    end
  end

  defp translate_price_type("regular", %Cart{} = cart) do
    dgettext("orders", "Regular price (%{price})", price: cart_regular_total(cart))
  end

  defp translate_price_type("promotional", %Cart{} = cart) do
    dgettext("orders", "Teiqui price (%{price})", price: cart_promotional_total(cart))
  end

  defp update_cart_if_needed(
         %{assigns: %{order: %{cart: %{price_type: old_type}}}} = socket,
         %{"cart" => %{"price_type" => new_type}}
       ) do
    case old_type == "promotional" || old_type == new_type do
      true -> socket
      _ -> update_cart_price_type(socket, new_type)
    end
  end

  defp update_cart_if_needed(socket, _params), do: socket

  defp update_cart_price_type(
         %{assigns: %{order: order, session: %{account: account}}} = socket,
         type
       ) do
    case Tq2.Transactions.update_cart(account, order.cart, %{price_type: type}) do
      {:ok, cart} ->
        cart = %{cart | payments: order.cart.payments}
        order = %{order | cart: cart}

        socket |> assign(:order, order)

      {:error, changeset} ->
        errors =
          changeset.errors
          |> Enum.map(fn {_k, error} -> Tq2Web.ErrorHelpers.translate_error(error) end)
          |> Enum.join("<br>")

        socket |> put_flash(:error, errors)
    end
  end

  defp order_attrs(%{assigns: %{order: %{data: %{paid: true}}}}, attrs), do: attrs

  defp order_attrs(%{assigns: %{order: order}}, attrs) do
    paid? = Cart.paid?(order.cart)

    data =
      (order.data || %Tq2.Sales.Data{})
      |> Map.from_struct()
      |> Map.new(fn {k, v} -> {"#{k}", v} end)
      |> Map.put("paid", paid?)

    attrs |> Map.put("data", data)
  end
end
