defmodule Tq2Web.Store.HandingLive do
  use Tq2Web, :live_view

  alias Tq2.{Shops, Transactions}
  alias Tq2Web.Store.{ButtonComponent, HeaderComponent}

  @impl true
  def mount(%{"slug" => slug}, %{"token" => token, "visit_id" => visit_id}, socket) do
    store = Shops.get_store!(slug)

    socket =
      socket
      |> assign(store: store, token: token, visit_id: visit_id)
      |> load_cart(token)

    {:ok, socket, temporary_assigns: [cart: nil]}
  end

  @impl true
  def handle_event(
        "save",
        %{"kind" => kind},
        %{assigns: %{store: %{account: account}, token: token}} = socket
      ) do
    cart = Transactions.get_cart(account, token)
    data = (cart.data || %Tq2.Transactions.Data{}) |> Map.from_struct()

    case Transactions.update_cart(account, cart, %{data: %{data | handing: kind}}) do
      {:ok, cart} ->
        {:noreply, assign(socket, cart: cart)}

      {:error, %Ecto.Changeset{}} ->
        # TODO: handle this case properly
        {:noreply, socket}
    end
  end

  defp load_cart(%{assigns: %{store: %{account: account}}} = socket, token) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end
end
