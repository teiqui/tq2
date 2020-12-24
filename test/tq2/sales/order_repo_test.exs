defmodule Tq2.Sales.OrderRepoTest do
  use Tq2.DataCase
  import Tq2.Fixtures, only: [create_session: 0, create_customer: 0]

  alias Tq2.Accounts
  alias Tq2.Sales.Order

  @valid_attrs %{
    status: "pending",
    cart_id: 1,
    promotion_expires_at: Timex.now() |> Timex.shift(days: 1)
  }

  defp session_fixture(_) do
    %{session: create_session()}
  end

  defp user_fixture(%{session: session}) do
    {:ok, user} =
      Accounts.create_user(session, %{
        email: "some@email.com",
        lastname: "some lastname",
        name: "some name",
        password: "123456"
      })

    %{user: %{user | password: nil}}
  end

  def order_fixture(%{session: session}) do
    {:ok, cart} =
      Tq2.Transactions.create_cart(session.account, %{
        token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoo=",
        customer_id: create_customer().id,
        data: %{handing: "pickup"}
      })

    {:ok, item} =
      Tq2.Inventories.create_item(session, %{
        sku: "some sku",
        name: "some name",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS)
      })

    {:ok, _line} =
      Tq2.Transactions.create_line(cart, %{
        name: "some name",
        quantity: 42,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS),
        item: item
      })

    {:ok, order} = Tq2.Sales.create_order(session.account, %{@valid_attrs | cart_id: cart.id})

    %{order: order}
  end

  describe "order" do
    setup [:session_fixture, :user_fixture, :order_fixture]

    use Bamboo.Test

    alias Tq2.Notifications.Email

    test "notify", %{user: owner, order: order} do
      {:ok, order} = Order.notify({:ok, order})

      assert_delivered_email(Email.new_order(order, owner))
      assert_delivered_email(Email.new_order(order, order.customer))
    end
  end
end
