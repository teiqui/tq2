defmodule Tq2.NotificationsTest do
  use Tq2.DataCase
  use Bamboo.Test

  import Tq2.Fixtures, only: [default_account: 0]

  alias Tq2.Accounts.User
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
      cart: %Cart{
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
    }
  end
end
