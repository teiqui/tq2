defmodule Tq2Web.Store.NotificationComponentTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  alias Tq2Web.Store.NotificationComponent

  describe "render" do
    test "render default notification" do
      content =
        render_component(NotificationComponent,
          id: :notification,
          customer_id: 1,
          inner_block: fn _, _ -> "Test content" end
        )

      assert content =~ "phx-hook=\"Notification\""
      refute content =~ "Test content"
    end

    test "render explicit ask for notifications" do
      content =
        render_component(NotificationComponent,
          id: :notification,
          customer_id: 1,
          ask_for_notifications: true,
          inner_block: fn _, _ -> "Test content" end
        )

      assert content =~ "phx-hook=\"Notification\""
      assert content =~ "Test content"
    end
  end
end
