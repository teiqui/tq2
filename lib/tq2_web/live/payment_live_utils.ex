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
    attrs = sale_attrs(cart)

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

  defp sale_attrs(cart) do
    attrs = %{
      cart_id: cart.id,
      promotion_expires_at: Timex.now() |> Timex.shift(days: 1),
      data: %{}
    }

    case cart.payments do
      %Ecto.Association.NotLoaded{} -> attrs
      [] -> attrs
      _ -> %{attrs | data: %{paid: Cart.paid?(cart)}}
    end
  end
end
