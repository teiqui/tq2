defmodule Tq2.Workers.NotificationsJobTest do
  use Tq2.DataCase

  import Mock

  import Tq2.Fixtures,
    only: [
      create_cart: 0,
      create_customer_subscription: 1,
      create_note: 0,
      create_order: 0,
      create_user_subscription: 1,
      default_account: 0,
      user_fixture: 1
    ]

  alias Tq2.Messages
  alias Tq2.Notifications.Email
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

    test "perform/2 should notify note" do
      mock = fn _body, _subscription -> {:ok, %{}} end
      %{note: note} = create_note()

      account = default_account()
      user = user_fixture(%Tq2.Accounts.Session{account: account})

      with_mock WebPushEncryption, send_web_push: mock do
        NotificationsJob.perform("new_note", note.id)

        assert_not_called(WebPushEncryption.send_web_push(:_, :_))

        jobs = Exq.Mock.jobs() |> Enum.filter(&(&1.class == Tq2.Workers.MailerJob))
        email = Email.new_note(note, user)
        job = jobs |> List.first()

        assert Enum.count(jobs) == 1
        assert job.class == Tq2.Workers.MailerJob
        assert List.first(job.args).private == email.private

        create_user_subscription(user.id)

        NotificationsJob.perform("new_note", note.id)

        assert_called(WebPushEncryption.send_web_push(:_, :_))

        jobs = Exq.Mock.jobs() |> Enum.filter(&(&1.class == Tq2.Workers.MailerJob))
        email = Email.new_note(note, user)
        job = jobs |> List.last()

        assert Enum.count(jobs) == 2
        assert job.class == Tq2.Workers.MailerJob
        assert List.first(job.args).private == email.private
      end
    end

    test "perform/4 should notify owner an abandoned cart" do
      mock = fn _body, _subscription -> {:ok, %{}} end

      cart = create_cart()
      user = user_fixture(%Tq2.Accounts.Session{account: cart.account})

      with_mock WebPushEncryption, send_web_push: mock do
        :ok =
          NotificationsJob.perform(
            "notify_abandoned_cart_to_user",
            cart.account_id,
            cart.token
          )

        assert_not_called(WebPushEncryption.send_web_push(:_, :_))

        create_user_subscription(user.id)

        :ok =
          NotificationsJob.perform(
            "notify_abandoned_cart_to_user",
            cart.account_id,
            cart.token
          )

        assert_called(WebPushEncryption.send_web_push(:_, :_))
      end
    end

    test "perform/4 should not notify already completed cart" do
      mock = fn _body, _subscription -> {:ok, %{}} end
      cart = create_cart()

      {:ok, _} =
        Tq2.Sales.create_order(
          cart.account,
          %{
            cart_id: cart.id,
            promotion_expires_at: Timex.now() |> Timex.shift(days: 1),
            status: "pending"
          }
        )

      with_mock WebPushEncryption, send_web_push: mock do
        refute NotificationsJob.perform(
                 "notify_abandoned_cart_to_user",
                 cart.account_id,
                 cart.token
               )

        assert_not_called(WebPushEncryption.send_web_push(:_, :_))
      end
    end

    test "perform/4 should send to customer a reminder email" do
      cart = create_cart()

      mailer =
        NotificationsJob.perform(
          "notify_abandoned_cart_to_customer",
          cart.account_id,
          cart.token
        )

      assert "Finish your purchase!" == mailer.subject
    end
  end
end
