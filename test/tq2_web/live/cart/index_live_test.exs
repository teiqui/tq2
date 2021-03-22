defmodule Tq2Web.Cart.IndexLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_cart: 0, init_test_session: 1]

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
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          live(conn, Routes.cart_path(conn, :index))
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
      path = Routes.cart_path(conn, :index)
      {:ok, order_live, html} = live(conn, path)
      content = order_live |> render()

      assert html =~ "Abandoned carts"
      assert html =~ "#{cart.id}"
      assert content =~ "Abandoned carts"
      assert content =~ "#{cart.id}"
    end

    test "empty index", %{conn: conn, cart: cart} do
      cart.lines
      |> Enum.each(fn line ->
        assert Tq2.Transactions.delete_line(line)
      end)

      path = Routes.cart_path(conn, :index)
      {:ok, order_live, html} = live(conn, path)

      assert html =~ "There&#39;re no abandoned carts at the moment."
      assert render(order_live) =~ "There&#39;re no abandoned carts at the moment."
    end
  end
end
