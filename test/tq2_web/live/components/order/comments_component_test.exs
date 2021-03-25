defmodule Tq2Web.Order.CommentsComponentTest do
  use Tq2Web.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Tq2.Fixtures, only: [create_order: 1, default_account: 0]

  alias Tq2Web.Order.CommentsComponent

  describe "render" do
    setup :create_order

    test "render component with no comments", %{order: order} do
      content =
        render_component(
          CommentsComponent,
          socket: Tq2Web.Endpoint,
          order: order,
          account: default_account(),
          originator: "user"
        )

      assert content =~ "No messages yet"
      assert content =~ "The store owner must enable notifications"
    end

    test "render component with comments", %{order: order} do
      {:ok, comment} = Tq2.Messages.create_comment(%{body: "Test message", order_id: order.id})

      content =
        render_component(
          CommentsComponent,
          socket: Tq2Web.Endpoint,
          order: order,
          account: default_account(),
          originator: "user"
        )

      assert content =~ comment.body
      refute content =~ "No messages yet"
    end
  end
end
