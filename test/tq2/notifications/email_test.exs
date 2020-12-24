defmodule Tq2.Notifications.EmailTest do
  use ExUnit.Case
  use Bamboo.Test

  alias Tq2.Accounts.User
  alias Tq2.Notifications.Email
  alias Tq2.Payments.Payment
  alias Tq2.Sales.{Customer, Order}
  alias Tq2.Transactions.{Cart, Line}

  test "password reset email" do
    user = user()
    email = Email.password_reset(user)

    assert email.to == user.email
    assert email.html_body =~ user.password_reset_token
    assert email.text_body =~ user.password_reset_token
  end

  test "new order customer email" do
    order = order()
    customer = customer()
    email = Email.new_order(order, customer)

    assert email.to == customer.email
    assert email.html_body =~ customer.name
    assert email.html_body =~ "##{order.id}"
    assert email.text_body =~ customer.name
    assert email.text_body =~ "##{order.id}"
  end

  test "returns nil when order has customer without email" do
    order = order()
    customer = %{customer() | email: nil}

    assert Email.new_order(order, customer) == nil
  end

  test "returns nil when there is no recipient" do
    order = order()

    assert Email.new_order(order, nil) == nil
  end

  test "new order owner email" do
    order = order()
    user = user()
    email = Email.new_order(order, user)

    assert email.to == user.email
    assert email.html_body =~ user.name
    assert email.html_body =~ "##{order.id}"
    assert email.text_body =~ user.name
    assert email.text_body =~ "##{order.id}"
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
    %Order{
      id: 1,
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
