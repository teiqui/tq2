defmodule Tq2Web.PaymentLive do
  use Tq2Web, :live_view

  import Tq2Web.ButtonComponent, only: [cart_total: 1]

  alias Tq2.{Shops, Transactions}
  alias Tq2Web.HeaderComponent

  @impl true
  def mount(%{"slug" => slug}, %{"token" => token}, socket) do
    store = Shops.get_store!(slug)

    socket =
      socket
      |> assign(store: store, token: token)
      |> load_cart(token)

    {:ok, socket, temporary_assigns: [cart: nil]}
  end

  @impl true
  def handle_event(
        "update",
        %{"kind" => kind},
        %{assigns: %{store: %{account: account}, token: token}} = socket
      ) do
    cart = Transactions.get_cart(account, token)
    data = (cart.data || %Tq2.Transactions.Data{}) |> Map.from_struct()

    case Transactions.update_cart(account, cart, %{data: %{data | payment: kind}}) do
      {:ok, cart} ->
        {:noreply, assign(socket, cart: cart)}

      {:error, %Ecto.Changeset{}} ->
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save", _params, socket) do
    # TODO: implement order creation
    {:noreply, socket}
  end

  defp load_cart(%{assigns: %{store: %{account: account}}} = socket, token) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end

  defp submit_payment(cart) do
    text = cart_total(cart)

    submit(text,
      class: "btn btn-lg btn-block btn-primary",
      disabled: !(cart.data && cart.data.payment),
      phx_disable_width: dgettext("payments", "Saving...")
    )
  end
end
