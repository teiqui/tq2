defmodule Tq2Web.Cart.ShowLiveTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_cart: 0, init_test_session: 1]
  import Tq2Web.Utils, only: [format_money: 1]

  alias Tq2.Transactions.Cart

  setup %{conn: conn} do
    two_days_ago = Timex.now() |> Timex.shift(days: -2)
    cart = create_cart()

    cart
    |> Ecto.Changeset.cast(%{updated_at: two_days_ago}, [:updated_at])
    |> Tq2.Repo.update!()

    cart = %{cart | updated_at: two_days_ago}

    {:ok, %{cart: cart, conn: conn}}
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn, cart: cart} do
      Enum.each(
        [
          live(conn, Routes.cart_path(conn, :show, cart.id))
        ],
        fn {:error, {:redirect, %{to: path}}} ->
          assert path =~ Routes.root_path(conn, :index)
        end
      )
    end
  end

  describe "render" do
    setup [:init_test_session]

    test "disconnected and connected render", %{conn: conn, cart: cart} do
      path = Routes.cart_path(conn, :show, cart)
      {:ok, order_live, html} = live(conn, path)
      content = order_live |> render()

      total =
        cart
        |> Cart.total()
        |> format_money()

      assert html =~ "Cart ##{cart.id}"
      assert content =~ "Cart ##{cart.id}"
      assert content =~ "Price type</strong>:\n<span class=\"text-primary\">Teiqui"
      assert content =~ cart.customer.name
      assert content =~ cart.customer.email
      assert content =~ cart.customer.phone
      assert content =~ total
    end
  end
end
