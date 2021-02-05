defmodule Tq2Web.Store.CustomerLive do
  use Tq2Web, :live_view

  import Tq2.Utils.CountryCurrency, only: [phone_prefix_for_ip: 1]

  alias Tq2.{Sales, Transactions}
  alias Tq2.Sales.Customer
  alias Tq2Web.Store.{ButtonComponent, HeaderComponent}

  @impl true
  def mount(
        _,
        %{"remote_ip" => ip, "store" => store, "token" => token, "visit_id" => visit_id},
        socket
      ) do
    socket
    |> assign(ip: ip, store: store, token: token, visit_id: visit_id, old_token: nil)
    |> load_customer()
    |> load_cart()
    |> put_changeset()
    |> finish_mount()
  end

  @impl true
  def handle_event("save", %{"customer" => customer_params}, %{assigns: %{token: token}} = socket) do
    customer_params =
      customer_params
      |> Map.put("tokens", [%{"value" => token}])
      |> clean_phone_prefix(socket)

    case save_customer(socket, customer_params) do
      {:ok, customer} ->
        socket =
          socket
          |> load_cart()
          |> assign(:customer, customer)
          |> associate()
          |> redirect()

        {:noreply, socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  @impl true
  def handle_event("save", _params, %{assigns: %{store: store, customer: _customer}} = socket) do
    socket =
      socket
      |> load_cart()
      |> associate()
      |> push_redirect(to: Routes.payment_path(socket, :index, store))

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "validate",
        %{"customer" => customer_params},
        %{assigns: %{token: token, store: store, customer: nil}} = socket
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
        params = customer_params |> clean_phone_prefix(socket)

        changeset =
          %Customer{}
          |> Sales.change_customer(params, store)
          |> Map.put(:action, :insert)

        socket =
          socket
          |> assign(:changeset, changeset)
          |> load_cart()

        {:noreply, socket}
    end
  end

  @impl true
  def handle_event(
        "validate",
        %{"customer" => customer_params},
        %{assigns: %{customer: customer, store: store}} = socket
      ) do
    changeset =
      customer
      |> Sales.change_customer(customer_params, store)
      |> Map.put(:action, :update)

    {:noreply, assign(socket, changeset: changeset)}
  end

  @impl true
  def handle_event("reset", _params, %{assigns: %{token: old_token}} = socket) do
    token = Customer.random_token()
    changeset = %Customer{} |> Sales.change_customer()

    socket =
      socket
      |> assign(customer: nil, changeset: changeset, token: token, old_token: old_token)

    {:noreply, socket}
  end

  @impl true
  def handle_event("edit", _params, %{assigns: %{customer: customer}} = socket) do
    changeset =
      customer
      |> Sales.change_customer()
      |> Map.put(:action, :update)

    {:noreply, assign(socket, :changeset, changeset)}
  end

  defp finish_mount(%{assigns: %{cart: nil, store: store}} = socket) do
    socket =
      socket
      |> push_redirect(to: Routes.counter_path(socket, :index, store))

    {:ok, socket}
  end

  defp finish_mount(socket) do
    {:ok, socket, temporary_assigns: [cart: nil, changeset: nil]}
  end

  defp load_cart(%{assigns: %{store: %{account: account}, token: token}} = socket) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end

  defp load_customer(%{assigns: %{customer: _}} = socket), do: socket

  defp load_customer(%{assigns: %{token: token}} = socket) do
    customer = Sales.get_customer(token)

    assign(socket, customer: customer)
  end

  defp put_changeset(%{assigns: %{customer: customer}} = socket) do
    changeset = Sales.change_customer(customer || %Customer{})

    socket |> assign(:changeset, changeset)
  end

  defp save_customer(%{assigns: %{customer: nil, old_token: nil, store: store}}, params) do
    Sales.create_customer(params, store)
  end

  defp save_customer(
         %{assigns: %{customer: nil, token: token, old_token: old_token, store: store}},
         params
       ) do
    Sales.create_customer(params, store, token, old_token)
  end

  defp save_customer(%{assigns: %{customer: customer, store: store}}, params) do
    Sales.update_customer(customer, params, store)
  end

  defp associate(%{assigns: %{store: store, customer: customer, cart: cart}} = socket) do
    case Transactions.update_cart(store.account, cart, %{customer_id: customer.id}) do
      {:ok, cart} ->
        assign(socket, cart: cart)

      {:error, %Ecto.Changeset{}} ->
        socket
    end
  end

  def input_phone_number(%{ip: ip}, form, field) do
    case input_value(form, field) do
      v when v in [nil, ""] -> phone_prefix_for_ip(ip)
      v -> v
    end
  end

  defp clean_phone_prefix(%{"phone" => value} = params, %{assigns: %{ip: ip}}) do
    prefix = phone_prefix_for_ip(ip)

    if value == prefix, do: %{params | "phone" => nil}, else: params
  end

  defp redirect(%{assigns: %{store: store, old_token: nil}} = socket) do
    push_redirect(socket, to: Routes.payment_path(socket, :index, store))
  end

  defp redirect(%{assigns: %{store: store, token: token}} = socket) do
    redirect(socket, to: Routes.token_path(socket, :show, store, token))
  end
end
