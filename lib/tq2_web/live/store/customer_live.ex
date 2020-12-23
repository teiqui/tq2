defmodule Tq2Web.Store.CustomerLive do
  use Tq2Web, :live_view

  import Tq2Web.Store.ButtonComponent, only: [cart_total: 1]

  alias Tq2.{Sales, Shops, Transactions}
  alias Tq2.Sales.Customer
  alias Tq2Web.Store.HeaderComponent

  @impl true
  def mount(%{"slug" => slug}, %{"token" => token}, socket) do
    store = Shops.get_store!(slug)
    changeset = get_customer_changeset(token)

    socket =
      socket
      |> assign(store: store, token: token, changeset: changeset)
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
        %{assigns: %{token: token}} = socket
      ) do
    email = customer_params["email"]
    phone = customer_params["phone"]

    case Sales.get_customer(email: email, phone: phone) do
      %Customer{} = customer ->
        changeset = Sales.change_customer(customer)

        socket =
          socket
          |> assign(customer: customer, changeset: changeset)
          |> load_cart(token)

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

  defp submit_customer(cart) do
    text = cart_total(cart)

    submit(text,
      class: "btn btn-lg btn-block btn-primary",
      phx_disable_width: dgettext("customers", "Saving...")
    )
  end
end