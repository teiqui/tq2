defmodule Tq2.Workers.NotificationsJobTest do
  use Tq2.DataCase

  import Mock

  import Tq2.Fixtures,
    only: [
      create_order: 0,
      create_customer_subscription: 1,
      create_user_subscription: 1,
      user_fixture: 1
    ]

  alias Tq2.Messages
  alias Tq2.Workers.NotificationsJob

  describe "notifications" do
    test "perform/4 should notify order" do
      mock = fn _body, _subscription -> {:ok, %{}} end
      %{order: order} = create_order()
      user = user_fixture(%Tq2.Accounts.Session{account: order.account})

      with_mock WebPushEncryption, send_web_push: mock do
        NotificationsJob.perform("new_order", order.account_id, order.id, user.id)

        assert_not_called(WebPushEncryption.send_web_push(:_, :_))

        create_user_subscription(user.id)

        NotificationsJob.perform("new_order", order.account_id, order.id, user.id)

        assert_called(WebPushEncryption.send_web_push(:_, :_))
      end
    end

    test "perform/5 should notify comment to customer" do
      mock = fn _body, _subscription -> {:ok, %{}} end
      %{order: order} = create_order()
      {:ok, comment} = Messages.create_comment(%{body: "Test comment", order_id: order.id})

      assert comment.status == "created"

      with_mock WebPushEncryption, send_web_push: mock do
        {:ok, comment} =
          NotificationsJob.perform(
            "new_comment",
            order.account_id,
            order.id,
            order.cart.customer_id,
            comment.id
          )

        assert comment.status == "delivered"
        assert_not_called(WebPushEncryption.send_web_push(:_, :_))

        create_customer_subscription(order.cart.customer_id)

        {:ok, _comment} =
          NotificationsJob.perform(
            "new_comment",
            order.account_id,
            order.id,
            order.cart.customer_id,
            comment.id
          )

        assert_called(WebPushEncryption.send_web_push(:_, :_))
      end
    end

    test "perform/5 should notify comment to user" do
      mock = fn _body, _subscription -> {:ok, %{}} end
      %{order: order} = create_order()

      {:ok, comment} =
        Messages.create_comment(%{
          body: "Test comment",
          originator: "customer",
          order_id: order.id
        })

      user = user_fixture(%Tq2.Accounts.Session{account: order.account})

      assert comment.status == "created"

      with_mock WebPushEncryption, send_web_push: mock do
        {:ok, comment} =
          NotificationsJob.perform(
            "new_comment",
            order.account_id,
            order.id,
            order.cart.customer_id,
            comment.id
          )

        assert comment.status == "delivered"
        assert_not_called(WebPushEncryption.send_web_push(:_, :_))

        create_user_subscription(user.id)

        {:ok, _comment} =
          NotificationsJob.perform(
            "new_comment",
            order.account_id,
            order.id,
            order.cart.customer_id,
            comment.id
          )

        assert_called(WebPushEncryption.send_web_push(:_, :_))
      end
    end
  end
end
