defmodule Tq2Web.Store.PaymentCheckLive do
  use Tq2Web, :live_view

  import Tq2Web.PaymentLiveUtils, only: [check_payments_with_timer: 1]

  alias Tq2.Transactions
  alias Tq2Web.Store.HeaderComponent

  @impl true
  def mount(_, %{"store" => store, "token" => token, "visit_id" => visit_id}, socket) do
    socket
    |> assign(store: store, token: token, visit_id: visit_id)
    |> load_cart()
    |> check_payments_with_timer()
    |> finish_mount()
  end

  @impl true
  def handle_info({:timer}, socket) do
    socket = socket |> check_payments_with_timer()

    {:noreply, socket}
  end

  defp finish_mount(%{assigns: %{cart: nil, store: store}} = socket) do
    socket =
      socket
      |> push_redirect(to: Routes.counter_path(socket, :index, store))

    {:ok, socket}
  end

  defp finish_mount(socket), do: {:ok, socket}

  defp load_cart(%{assigns: %{store: %{account: account}, token: token}} = socket) do
    cart = Transactions.get_cart(account, token)

    assign(socket, cart: cart)
  end
end
