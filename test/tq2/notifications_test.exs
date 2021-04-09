defmodule Tq2.NotificationsTest do
  use Tq2.DataCase
  use Bamboo.Test

  import Tq2.Fixtures, only: [default_account: 0, user_fixture: 1]

  alias Tq2.Accounts.User
  alias Tq2.Messages.Comment
  alias Tq2.Notifications
  alias Tq2.Notifications.Email
  alias Tq2.Payments.Payment
  alias Tq2.Sales.{Customer, Order}
  alias Tq2.Transactions.{Cart, Line}

  test "password reset email" do
    user = user()

    Notifications.send_password_reset(user)

    assert_delivered_email(Email.password_reset(user))
  end

  test "new order email for user" do
    order = order()
    user = user()

    Notifications.send_new_order(order, user)

    assert_delivered_email(Email.new_order(order, user))
  end

  test "new order email for customer" do
    order = order()
    customer = customer()

    Notifications.send_new_order(order, customer)

    assert_delivered_email(Email.new_order(order, customer))
  end

  test "no new order email is sent for customer without email" do
    order = order()
    customer = %{customer() | email: nil}

    Notifications.send_new_order(order, customer)

    assert_no_emails_delivered()
  end

  test "no new order email is sent for nil recipient" do
    order = order()

    Notifications.send_new_order(order, nil)

    assert_no_emails_delivered()
  end

  test "promotion confirmation email for customer" do
    order = %{order() | customer: customer()}

    Notifications.send_promotion_confirmation(order)

    assert_delivered_email(Email.promotion_confirmation(order))
  end

  test "no promotion confirmation email is sent for customer without email" do
    order = %{order() | customer: %{customer() | email: nil}}

    Notifications.send_promotion_confirmation(order)

    assert_no_emails_delivered()
  end

  test "expired promotion email for customer" do
    order = %{order() | customer: customer()}

    Notifications.send_expired_promotion(order)

    assert_delivered_email(Email.expired_promotion(order))
  end

  test "no expired promotion email is sent for customer without email" do
    order = %{order() | customer: %{customer() | email: nil}}

    Notifications.send_expired_promotion(order)

    assert_no_emails_delivered()
  end

  test "license expired" do
    user = user()

    Notifications.send_license_expired(user)

    assert_delivered_email(Email.license_expired(user))
  end

  test "license near to expire" do
    user = user()

    Notifications.send_license_near_to_expire(user)

    assert_delivered_email(Email.license_near_to_expire(user))
  end

  test "notify new order" do
    order = order()
    user = user()

    Notifications.notify_new_order(order, user)

    job = Exq.Mock.jobs() |> List.first()

    assert job.class == Tq2.Workers.NotificationsJob
    assert job.args == ["new_order", order.account_id, order.id, user.id]
  end

  test "notify new comment" do
    comment = comment()

    Notifications.notify_new_comment(comment)

    job = Exq.Mock.jobs() |> List.first()

    assert job.class == Tq2.Workers.NotificationsJob

    assert job.args == [
             "new_comment",
             comment.order.account_id,
             comment.order.id,
             comment.customer.id,
             comment.id
           ]
  end

  test "cart reminder" do
    cart = cart()
    customer = customer()

    Notifications.send_cart_reminder(cart, customer)

    assert_delivered_email(Email.cart_reminder(cart, customer))
  end

  test "no cart reminder" do
    cart = cart()
    customer = %{customer() | email: nil}

    Notifications.send_cart_reminder(cart, customer)

    assert_no_emails_delivered()
  end

  describe "subscriptions" do
    alias Tq2.Notifications.Subscription

    @valid_attrs %{
      "hash" => "ffed703971737ad05c9f5e9939d5b6434faf0bd9ae0ef95e9ee58b89a8e66b62",
      "error_count" => 0,
      "data" => %{
        "endpoint" => "https://fcm.googleapis.com/fcm/send/some_random_things",
        "keys" => %{"p256dh" => "p256dh_key", "auth" => "auth_string"}
      },
      "subscription_user" => %{
        "user_id" => 1
      }
    }
    @update_attrs %{
      "hash" => "2259549e5dbdc8d2b2dfb79897a211de914e889026ca9c1956fa00ccef26b80e",
      "error_count" => 0,
      "data" => %{
        "endpoint" => "https://fcm.googleapis.com/fcm/send/some_updated_random_things",
        "keys" => %{"p256dh" => "updated_p256dh_key", "auth" => "updated_auth_string"}
      },
      "subscription_user" => %{
        "user_id" => 1
      }
    }
    @invalid_attrs %{
      "hash" => nil,
      "error_count" => nil,
      "data" => %{
        "endpoint" => "",
        "keys" => %{"p256dh" => nil, "auth" => ""}
      },
      "subscription_user" => %{
        "user_id" => nil
      }
    }

    defp fixture(:subscription, attrs \\ %{}) do
      user = user_fixture(nil)

      subscription_attrs =
        Enum.into(attrs, %{@valid_attrs | "subscription_user" => %{"user_id" => user.id}})

      {:ok, subscription} = Notifications.create_subscription(subscription_attrs)

      %{subscription: subscription, user: user}
    end

    test "get_subscription/1 returns the subscription with given endpoint and auth" do
      %{subscription: subscription, user: user} = fixture(:subscription)
      attrs = %{@valid_attrs | "subscription_user" => %{"user_id" => user.id}}

      assert Notifications.get_subscription(attrs).id == subscription.id
    end

    test "create_subscription/1 with valid data creates a subscription" do
      user = user_fixture(nil)
      attrs = %{@valid_attrs | "subscription_user" => %{"user_id" => user.id}}

      assert {:ok, %Subscription{} = subscription} = Notifications.create_subscription(attrs)
      assert subscription.hash == @valid_attrs["hash"]
      assert subscription.error_count == @valid_attrs["error_count"]
      assert subscription.data.endpoint == @valid_attrs["data"]["endpoint"]
    end

    test "create_subscription/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Notifications.create_subscription(@invalid_attrs)
    end

    test "update_subscription/2 with valid data updates the subscription" do
      %{subscription: subscription, user: user} = fixture(:subscription)
      attrs = %{@update_attrs | "subscription_user" => %{"user_id" => user.id}}

      assert {:ok, subscription} = Notifications.update_subscription(subscription, attrs)
      assert %Subscription{} = subscription
      assert subscription.hash == @update_attrs["hash"]
      assert subscription.error_count == @update_attrs["error_count"]
      assert subscription.data.endpoint == @update_attrs["data"]["endpoint"]
    end

    test "update_subscription/2 with invalid data returns error changeset" do
      %{subscription: subscription, user: user} = fixture(:subscription)
      attrs = %{@valid_attrs | "subscription_user" => %{"user_id" => user.id}}

      assert {:error, %Ecto.Changeset{}} =
               Notifications.update_subscription(subscription, @invalid_attrs)

      assert subscription.hash == Notifications.get_subscription(attrs).hash
    end
  end

  defp user do
    %User{
      name: "John",
      email: "some@email.com",
      password_reset_token: "test-token"
    }
  end

  defp customer do
    %Customer{
      name: "some name",
      email: "some@email.com",
      phone: "555-5555",
      address: "some address"
    }
  end

  defp comment do
    %Comment{
      id: 1,
      body: "some text",
      status: "created",
      originator: "user",
      customer: customer(),
      order: order()
    }
  end

  defp order do
    account = default_account()

    %Order{
      id: 1,
      account_id: account.id,
      account: account,
      status: "pending",
      promotion_expires_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      inserted_at: Timex.now(),
      customer: %Customer{name: "Sample"},
      cart: cart()
    }
  end

  defp cart do
    account = default_account()

    %Cart{
      id: 1,
      account_id: account.id,
      account: account,
      data: %{handing: "pickup"},
      lines: [
        %Line{
          name: "line1",
          quantity: 2,
          price: Money.new(100, "ARS"),
          promotional_price: Money.new(90, "ARS")
        }
      ],
      payments: [
        %Payment{
          kind: "mercado_pago",
          status: "pending",
          amount: Money.new(180, "ARS"),
          inserted_at: Timex.now()
        }
      ]
    }
  end
end
