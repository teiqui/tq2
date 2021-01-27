defmodule Tq2Web.Order.OrderEditLive do
  use Tq2Web, :live_view

  alias Tq2.Accounts
  alias Tq2.Sales
  alias Tq2Web.Order.PaymentsComponent

  @statuses %{
    dgettext("orders", "Pending") => "pending",
    dgettext("orders", "Processing") => "processing",
    dgettext("orders", "Completed") => "completed",
    dgettext("orders", "Canceled") => "canceled"
  }

  @impl true
  def mount(%{"id" => id}, %{"account_id" => account_id, "user_id" => user_id}, socket) do
    session = Accounts.get_current_session(account_id, user_id)

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
  def handle_event("save", %{"order" => attrs}, socket) do
    socket = socket |> update_order(attrs)

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
    case Sales.update_order(session, order, attrs) do
      {:ok, order} ->
        socket
        |> put_flash(:info, dgettext("orders", "Order updated successfully."))
        |> redirect(to: Routes.order_path(socket, :show, order))

      {:error, %Ecto.Changeset{} = changeset} ->
        socket |> assign(changeset: changeset)
    end
  end
end
