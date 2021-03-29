defmodule Tq2.Notifications.EmailTest do
  use Tq2.DataCase
  use Bamboo.Test

  import Tq2.Fixtures, only: [default_store: 1, default_account: 0, user_fixture: 2]
  import Tq2.Utils.Urls, only: [store_uri: 0]

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
    assert email.headers["Reply-To"] == "some name <store@some_slug.com>"
    assert email.html_body =~ customer.name
    assert email.html_body =~ "##{order.id}"
    assert email.text_body =~ customer.name
    assert email.text_body =~ "##{order.id}"
  end

  test "new order returns nil when order has customer without email" do
    order = order()
    customer = %{customer() | email: nil}

    assert Email.new_order(order, customer) == nil
  end

  test "new order returns nil when there is no recipient" do
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

  test "promotion confirmation email" do
    order = %{order() | customer: customer()}
    email = Email.promotion_confirmation(order)

    assert email.to == order.customer.email
    assert email.headers["Reply-To"] == "some name <store@some_slug.com>"
    assert email.html_body =~ order.customer.name
    assert email.html_body =~ "##{order.id}"
    assert email.text_body =~ order.customer.name
    assert email.text_body =~ "##{order.id}"
  end

  test "promotion confirmation returns nil when order has customer without email" do
    order = %{order() | customer: %{customer() | email: nil}}

    assert Email.promotion_confirmation(order) == nil
  end

  test "expired promotion email" do
    order = %{order() | customer: customer()}
    order = %{order | cart: %{order.cart | price_type: "regular"}}
    line = order.cart.lines |> List.first()
    price = line.price |> Money.to_string(symbol: true)
    promotional_price = line.promotional_price |> Money.to_string(symbol: true)

    email = Email.expired_promotion(order)
    order_path = Tq2Web.Router.Helpers.order_path(%URI{}, :index, default_store(%{}), order)

    assert email.to == order.customer.email
    assert email.headers["Reply-To"] == "some name <store@some_slug.com>"
    assert email.subject =~ "Promotional price expired"
    assert email.html_body =~ order.customer.name
    assert email.html_body =~ "##{order.id}"
    assert email.html_body =~ price
    refute email.html_body =~ promotional_price
    assert email.html_body =~ "You can change the payment method "
    assert email.html_body =~ order_path
    assert email.text_body =~ order.customer.name
    assert email.text_body =~ "##{order.id}"
    assert email.text_body =~ price
    refute email.text_body =~ promotional_price
    assert email.text_body =~ "You can change the payment method "
    assert email.text_body =~ order_path
  end

  test "expired promotion returns nil when order has customer without email" do
    order = %{order() | customer: %{customer() | email: nil}}

    assert Email.expired_promotion(order) == nil
  end

  test "customer emails without store email and owner, reply to default email" do
    store_without_email()

    order = order()
    customer = customer()
    email = Email.new_order(order, customer)

    default_email = System.get_env("EMAIL_ADDRESS", "support@teiqui.com")

    assert email.to == customer.email
    assert email.headers["Reply-To"] == default_email
    assert email.html_body =~ customer.name
    assert email.html_body =~ "##{order.id}"
    assert email.text_body =~ customer.name
    assert email.text_body =~ "##{order.id}"
  end

  test "customer emails without store email, reply to owner email" do
    store_without_email()

    user_fixture(nil, %{email: "owner@some_slug.com"})

    order = order()
    customer = customer()
    email = Email.new_order(order, customer)

    assert email.to == customer.email
    assert email.headers["Reply-To"] == "some name <owner@some_slug.com>"
    assert email.html_body =~ customer.name
    assert email.html_body =~ "##{order.id}"
    assert email.text_body =~ customer.name
    assert email.text_body =~ "##{order.id}"
  end

  test "expired license" do
    user = user()
    email = Email.license_expired(user)

    assert email.to == user.email
    assert email.subject == "License expired"
    assert email.html_body =~ user.name
    assert email.html_body =~ "/license"
    assert email.text_body =~ user.name
    assert email.text_body =~ "/license"
  end

  test "license near to expire" do
    user = user()
    email = Email.license_near_to_expire(user)

    assert email.to == user.email
    assert email.subject == "License near to expire"
    assert email.html_body =~ user.name
    assert email.html_body =~ "/license"
    assert email.text_body =~ user.name
    assert email.text_body =~ "/license"
  end

  test "cart reminder" do
    cart = cart()
    customer = customer()
    email = cart |> Email.cart_reminder(customer)
    store = default_store(%{})

    url = store_uri() |> Tq2Web.Router.Helpers.cart_url(:show, store, cart.id)

    assert email.to == customer.email
    assert email.subject == "Finish your purchase!"
    assert email.html_body =~ customer.name
    assert email.html_body =~ url
    assert email.text_body =~ customer.name
    assert email.text_body =~ url
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
      cart: cart()
    }
  end

  defp cart do
    account = default_account()

    %Cart{
      id: 1,
      account: account,
      account_id: account.id,
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

  defp store_without_email do
    store = default_store(%{})
    data = store.data |> Map.from_struct() |> Map.put(:email, nil)

    default_store(%{data: data})
  end
end
