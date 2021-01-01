defmodule Tq2Web.PaymentLiveUtils do
  import Phoenix.LiveView, only: [push_redirect: 2]

  alias Tq2.Sales
  alias Tq2.Transactions.Cart
  alias Tq2Web.Router.Helpers, as: Routes

  def get_or_create_order(socket, cart) do
    cart = Tq2.Repo.preload(cart, :order)
    store = socket.assigns.store

    case cart.order do
      nil -> create_order(socket, store, cart)
      order -> socket |> push_redirect(to: Routes.order_path(socket, :index, store, order))
    end
  end

  def create_order(socket, store, cart) do
    attrs = order_attrs(store.account, cart)

    case Sales.create_order(store.account, attrs) do
      {:ok, order} ->
        socket |> push_redirect(to: Routes.order_path(socket, :index, store, order))

      {:error, %Ecto.Changeset{}} ->
        # TODO: handle this case properly
        socket
    end
  end

  def check_for_paid_cart(%{assigns: %{cart: cart}} = socket) do
    case Cart.paid?(cart) do
      true -> get_or_create_order(socket, cart)
      false -> socket
    end
  end

  defp order_attrs(account, cart) do
    cart
    |> initial_order_attrs()
    |> build_order_tie(account, cart)
    |> mark_order_as_paid(cart)
  end

  def initial_order_attrs(%Cart{id: id}) do
    %{
      cart_id: id,
      promotion_expires_at: Timex.now() |> Timex.shift(days: 1),
      data: %{}
    }
  end

  defp build_order_tie(attrs, account, cart) do
    visit = Tq2.Analytics.get_visit!(cart.visit_id)

    case visit.referral_customer do
      nil -> attrs
      customer -> Map.put(attrs, :ties, build_order_tie(account, customer))
    end
  end

  defp build_order_tie(account, customer) do
    case Tq2.Sales.get_promotional_order_for(account, customer) do
      nil -> []
      order -> [%{originator_id: order.id}]
    end
  end

  defp mark_order_as_paid(attrs, %Cart{payments: %Ecto.Association.NotLoaded{}}), do: attrs
  defp mark_order_as_paid(attrs, %Cart{payments: []}), do: attrs
  defp mark_order_as_paid(attrs, cart), do: %{attrs | data: %{paid: Cart.paid?(cart)}}
end
