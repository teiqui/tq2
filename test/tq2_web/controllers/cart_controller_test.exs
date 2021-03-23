defmodule Tq2Web.CartControllerTest do
  use Tq2Web.ConnCase

  import Tq2.Fixtures, only: [create_cart: 1, create_item: 1, default_store: 0]

  setup %{conn: conn} do
    cart = create_cart(%{})

    conn =
      %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}
      |> Plug.Test.init_test_session(token: cart.token)

    {:ok, %{conn: conn, cart: cart, store: default_store()}}
  end

  describe "cart" do
    test "copy from cart", %{conn: conn, cart: cart, store: store} do
      item = create_item(%{name: "other item"})

      old_cart = create_cart(%{cart: %{customer: cart.customer, token: "123aaa"}, item: item})

      old_line = old_cart.lines |> List.first()
      cart_line = cart.lines |> List.first()

      refute old_line.id == cart_line.id
      refute old_line.item_id == cart_line.item_id

      conn = conn |> get(Routes.cart_path(conn, :show, store, old_cart.id))

      assert redirected_to(conn) == Routes.brief_path(conn, :index, store)

      cart = store.account |> Tq2.Transactions.get_cart!(cart.id)

      assert Enum.count(cart.lines) == 1

      line = cart.lines |> List.first()

      refute old_line.id == line.id
      refute cart_line.id == line.id
      assert old_line.item_id == line.item_id
    end

    test "redirect without changing cart for unexistent id", %{conn: conn, store: store} do
      assert_raise Ecto.NoResultsError, fn ->
        conn |> get(Routes.cart_path(conn, :show, store, 1))
      end
    end

    test "redirect without changing cart same id", %{
      conn: conn,
      cart: cart,
      store: store
    } do
      ids = cart.lines |> Enum.map(& &1.id)
      conn = conn |> get(Routes.cart_path(conn, :show, store, cart.id))

      assert redirected_to(conn) == Routes.brief_path(conn, :index, store)

      new_ids =
        store.account
        |> Tq2.Transactions.get_cart!(cart.id)
        |> Map.get(:lines)
        |> Enum.map(& &1.id)

      assert ids == new_ids
    end

    test "copy from cart without current cart", %{conn: conn, cart: cart, store: store} do
      conn =
        conn
        |> Plug.Test.init_test_session(token: "unknown")
        |> get(Routes.cart_path(conn, :show, store, cart.id))

      assert redirected_to(conn) == Routes.brief_path(conn, :index, store)

      token = conn |> get_session(:token)
      new_cart = store.account |> Tq2.Transactions.get_cart(token)
      old_cart = store.account |> Tq2.Transactions.get_cart!(cart.id)

      assert Enum.count(new_cart.lines) == 1

      line = new_cart.lines |> List.first()
      old_line = old_cart.lines |> List.first()

      refute old_line.id == line.id
      assert old_line.item_id == line.item_id
    end
  end
end
