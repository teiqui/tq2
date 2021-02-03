defmodule Tq2Web.Store.HandingLive do
  use Tq2Web, :live_view

  import Tq2Web.Utils, only: [format_money: 1]

  alias Tq2.Transactions
  alias Tq2Web.Store.{ButtonComponent, HeaderComponent}

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    socket
    |> assign(store: store, token: token, visit_id: visit_id)
    |> load_cart()
    |> put_changeset()
    |> finish_mount()
  end

  @impl true
  def handle_event(
        "save",
        %{"cart" => %{"data" => %{"handing" => handing} = params}},
        %{assigns: %{store: store, token: token}} = socket
      ) do
    cart = Transactions.get_cart(store.account, token)
    shipping = shipping_from_params(store, params)

    data =
      cart.data
      |> Transactions.Data.from_struct()
      |> Map.merge(%{handing: handing, shipping: shipping})

    case Transactions.update_cart(store.account, cart, %{data: data}) do
      {:ok, cart} ->
        socket =
          socket
          |> assign(cart: cart)
          |> put_changeset()

        {:noreply, socket}

      {:error, changeset} ->
        socket = socket |> assign(cart: cart, changeset: changeset)

        {:noreply, socket}
    end
  end

  defp finish_mount(%{assigns: %{cart: nil, store: store}} = socket) do
    socket =
      socket
      |> push_redirect(to: Routes.counter_path(socket, :index, store))

    {:ok, socket}
  end

  defp finish_mount(socket) do
    {:ok, socket, temporary_assigns: [cart: nil]}
  end

  defp load_cart(%{assigns: %{store: %{account: account}, token: token}} = socket) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end

  defp delivery?(%{params: %{"handing" => "delivery"}}), do: true
  defp delivery?(%{data: %{handing: "delivery"}}), do: true
  defp delivery?(_data_form), do: false

  defp put_changeset(%{assigns: %{cart: nil}} = socket), do: socket

  defp put_changeset(%{assigns: %{cart: cart, store: %{account: account}}} = socket) do
    changeset = account |> Transactions.change_handing_cart(cart)

    socket |> assign(changeset: changeset)
  end

  defp shipping_from_params(
         %{configuration: %{shippings: shippings}},
         %{"handing" => "delivery", "shipping" => %{"id" => id}}
       )
       when id not in ["", nil] do
    shippings |> Enum.find(&(&1.id == id)) |> Map.from_struct()
  end

  defp shipping_from_params(_store, _params), do: nil
end
