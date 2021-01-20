defmodule Tq2Web.Store.CustomerLive do
  use Tq2Web, :live_view

  import Tq2Web.Store.ButtonComponent, only: [cart_total: 1]

  alias Tq2.{Sales, Transactions}
  alias Tq2.Sales.Customer
  alias Tq2Web.Store.HeaderComponent

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    changeset = get_customer_changeset(token)

    socket =
      socket
      |> assign(store: store, token: token, visit_id: visit_id, changeset: changeset)
      |> load_customer(token)
      |> load_cart(token)

    {:ok, socket, temporary_assigns: [cart: nil, changeset: nil, customer: nil]}
  end

  @impl true
  def handle_event(
        "save",
        %{"customer" => customer_params},
        %{assigns: %{store: store, token: token}} = socket
      ) do
    customer_params = customer_params |> Map.put("tokens", [%{"value" => token}])

    case customer(customer_params, token) do
      {:ok, customer} ->
        socket =
          socket
          |> load_cart(token)
          |> assign(:customer, customer)
          |> associate()
          |> push_redirect(to: Routes.payment_path(socket, :index, store))

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event(
        "validate",
        %{"customer" => customer_params},
        %{assigns: %{token: token, store: store}} = socket
      ) do
    email = customer_params["email"]
    phone = customer_params["phone"]

    case Sales.get_customer(email: email, phone: phone) do
      %Customer{} = customer ->
        {:ok, _token} = Tq2.Shares.create_token(%{customer_id: customer.id, value: token})

        socket =
          socket
          |> push_redirect(to: Routes.customer_path(socket, :index, store))

        {:noreply, socket}

      nil ->
        changeset =
          %Customer{}
          |> Sales.change_customer(customer_params)
          |> Map.put(:action, :insert)

        socket =
          socket
          |> assign(:changeset, changeset)
          |> load_cart(token)

        {:noreply, socket}
    end
  end

  defp load_cart(%{assigns: %{store: %{account: account}}} = socket, token) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end

  defp load_customer(%{assigns: %{customer: _}} = socket, _token), do: socket

  defp load_customer(socket, token) do
    customer = Sales.get_customer(token)

    assign(socket, customer: customer)
  end

  defp get_customer_changeset(token) do
    case Sales.get_customer(token) do
      %Customer{} = customer ->
        Sales.change_customer(customer)

      nil ->
        Sales.change_customer(%Customer{})
    end
  end

  defp customer(%{"email" => email, "phone" => phone} = params, _token) do
    case Sales.get_customer(email: email, phone: phone) do
      %Customer{} = customer ->
        {:ok, customer}

      nil ->
        Sales.create_customer(params)
    end
  end

  defp associate(%{assigns: %{store: store, customer: customer, cart: cart}} = socket) do
    case Transactions.update_cart(store.account, cart, %{customer_id: customer.id}) do
      {:ok, cart} ->
        assign(socket, cart: cart)

      {:error, %Ecto.Changeset{}} ->
        socket
    end
  end

  defp submit_customer(socket, cart) do
    content = ~E"""
      <%= cart_total(cart) %>

      <span class="float-right ml-n3">
        <svg class="bi" width="16" height="16" fill="currentColor">
          <use xlink:href="<%= Routes.static_path(socket, "/images/bootstrap-icons.svg#arrow-right") %>"/>
        </svg>
      </span>
    """

    submit(content,
      class: "btn btn-lg btn-block btn-primary",
      phx_disable_with: dgettext("customers", "Saving...")
    )
  end
end
