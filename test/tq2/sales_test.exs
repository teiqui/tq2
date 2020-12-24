defmodule Tq2.SalesTest do
  use Tq2.DataCase

  import Tq2.Fixtures, only: [create_customer: 0]

  alias Tq2.Sales

  @valid_customer_attrs %{
    name: "some name",
    email: "some@EMAIL.com",
    phone: "555-5555",
    address: "some address"
  }
  @invalid_customer_attrs %{
    name: nil,
    email: nil,
    phone: nil,
    address: nil
  }

  @valid_order_attrs %{
    status: "pending",
    promotion_expires_at:
      DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601(),
    cart: %{
      token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoM=",
      lines: [
        %{
          name: "some name",
          quantity: 42,
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          cost: Money.new(80, :ARS),
          item: %{
            sku: "some sku",
            name: "some name",
            visibility: "visible",
            price: Money.new(100, :ARS),
            promotional_price: Money.new(90, :ARS),
            cost: Money.new(80, :ARS)
          }
        }
      ]
    }
  }
  @update_order_attrs %{
    status: "processing",
    promotion_expires_at:
      DateTime.utc_now() |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  }
  @invalid_order_attrs %{
    status: nil,
    promotion_expires_at: nil
  }

  defp fixture(session, schema, attrs \\ %{})

  defp fixture(_session, :customer, attrs) do
    customer_attrs = Enum.into(attrs, @valid_customer_attrs)

    {:ok, customer} = Sales.create_customer(customer_attrs)

    customer
  end

  defp fixture(session, :order, attrs) do
    order_attrs = Enum.into(attrs, @valid_order_attrs)

    {:ok, order} = Sales.create_order(session.account, order_attrs)

    order
  end

  describe "customers" do
    alias Tq2.Sales.Customer

    test "get_customer!/1 returns the customer with given id" do
      customer = fixture(nil, :customer)

      assert Sales.get_customer!(customer.id) == customer
    end

    test "get_customer/1 returns the customer with given token" do
      customer = fixture(nil, :customer)

      {:ok, token} =
        Tq2.Shares.create_token(%{
          value: "hItfgIBvse62B_oZPgu6Ppp3qORvjbVCPEi9E-Poz2U=",
          customer_id: customer.id
        })

      assert Sales.get_customer(token.value) == customer
    end

    test "get_customer/1 returns the customer with given email or phone" do
      customer = fixture(nil, :customer)

      assert Sales.get_customer(email: String.upcase(" #{customer.email}")) == customer
      assert Sales.get_customer(phone: String.upcase(" #{customer.phone}x")) == customer
      assert Sales.get_customer(email: customer.email, phone: "non existing 123") == customer
      assert Sales.get_customer(email: "invalid@email.com", phone: "non existing 123") == nil
    end

    test "create_customer/1 with valid data creates a customer" do
      assert {:ok, %Customer{} = customer} = Sales.create_customer(@valid_customer_attrs)
      assert customer.name == @valid_customer_attrs.name
      assert customer.email == Customer.canonized_email(@valid_customer_attrs.email)
      assert customer.phone == Customer.canonized_phone(@valid_customer_attrs.phone)
      assert customer.address == @valid_customer_attrs.address
    end

    test "create_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sales.create_customer(@invalid_customer_attrs)
    end

    test "change_customer/1 returns a customer changeset" do
      customer = fixture(nil, :customer)

      assert %Ecto.Changeset{} = Sales.change_customer(customer)
    end
  end

  describe "orders" do
    setup [:create_session]

    use Bamboo.Test

    alias Tq2.Sales.Order
    alias Tq2.Notifications.Email

    defp create_session(_) do
      account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")

      {:ok, session: %Tq2.Accounts.Session{account: account}}
    end

    test "list_orders/2 returns all orders", %{session: session} do
      order = fixture(session, :order)

      assert Enum.map(Sales.list_orders(session.account, %{}).entries, & &1.id) == [order.id]
    end

    test "get_order!/2 returns the order with given id", %{session: session} do
      order = fixture(session, :order)

      assert Sales.get_order!(session.account, order.id).id == order.id
    end

    test "create_order/2 with valid data creates a order", %{session: session} do
      assert {:ok, %Order{} = order} = Sales.create_order(session.account, @valid_order_attrs)
      assert order.status == @valid_order_attrs.status

      assert DateTime.to_iso8601(order.promotion_expires_at) ==
               @valid_order_attrs.promotion_expires_at
    end

    test "create_order/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} =
               Sales.create_order(session.account, @invalid_order_attrs)
    end

    test "create_order/2 notifies to owner and customer", %{session: session} do
      {:ok, owner} = create_user(session)
      {:ok, cart} = create_cart(session)

      attrs =
        @valid_order_attrs
        |> Map.delete(:cart)
        |> Map.put(:cart_id, cart.id)

      assert {:ok, %Order{} = order} = Sales.create_order(session.account, attrs)

      assert_delivered_email(Email.new_order(order, owner))
      assert_delivered_email(Email.new_order(order, order.customer))
    end

    test "update_order/3 with valid data updates the order", %{session: session} do
      order = fixture(session, :order)

      assert {:ok, order} = Sales.update_order(session, order, @update_order_attrs)
      assert %Order{} = order
      assert order.status == @update_order_attrs.status

      assert DateTime.to_iso8601(order.promotion_expires_at) ==
               @update_order_attrs.promotion_expires_at
    end

    test "update_order/3 with invalid data returns error changeset", %{session: session} do
      order = fixture(session, :order)

      assert {:error, %Ecto.Changeset{}} =
               Sales.update_order(session, order, @invalid_order_attrs)

      assert order.status == Sales.get_order!(session.account, order.id).status
    end

    test "delete_order/2 deletes the order", %{session: session} do
      order = fixture(session, :order)

      assert {:ok, %Order{}} = Sales.delete_order(session, order)
      assert_raise Ecto.NoResultsError, fn -> Sales.get_order!(session.account, order.id) end
    end

    test "change_order/2 returns a order changeset", %{session: session} do
      order = fixture(session, :order)

      assert %Ecto.Changeset{} = Sales.change_order(session.account, order)
    end
  end

  defp create_user(session) do
    Tq2.Accounts.create_user(session, %{
      email: "some@email.com",
      lastname: "some lastname",
      name: "some name",
      password: "123456"
    })
  end

  defp create_cart(session) do
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

    {:ok, cart}
  end
end
