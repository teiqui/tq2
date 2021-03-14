defmodule Tq2Web.Order.CommentLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_order: 0, init_test_session: 1]

  def order_fixture(_) do
    create_order()
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          live(conn, Routes.comment_path(conn, :index, "1"))
        ],
        fn {:error, {:redirect, %{to: path}}} ->
          assert path =~ Routes.root_path(conn, :index)
        end
      )
    end
  end

  describe "render" do
    setup [:init_test_session, :order_fixture]

    test "disconnected and connected render", %{conn: conn, order: order} do
      path = Routes.comment_path(conn, :index, order)
      {:ok, comment_live, html} = live(conn, path)

      assert html =~ "Messages"
      assert render(comment_live) =~ "Messages"
    end

    test "save event", %{conn: conn, order: order} do
      path = Routes.comment_path(conn, :index, order)
      {:ok, comment_live, html} = live(conn, path)

      assert html =~ "No messages yet"
      assert render(comment_live) =~ "No messages yet"

      assert comment_live
             |> form("#comment-form", %{comment: %{body: "Test message"}})
             |> render_submit() =~ "Test message"

      refute render(comment_live) =~ "No messages yet"
    end
  end
end
