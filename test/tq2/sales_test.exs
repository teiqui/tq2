defmodule Tq2.SalesTest do
  use Tq2.DataCase

  import Tq2.Fixtures, only: [create_session: 0, default_account: 0, default_store: 0]

  alias Tq2.{Analytics, Sales}

  @valid_customer_attrs %{
    name: "some name",
    email: "some@EMAIL.com",
    phone: "555-5555",
    address: "some address"
  }
  @valid_customer_update_attrs %{
    name: "some updated name",
    email: "some_updated@EMAIL.com",
    phone: "555-7777",
    address: "some updated address"
  }
  @invalid_customer_attrs %{
    name: nil,
    email: nil,
    phone: nil,
    address: nil
  }

  @valid_visit_attrs %{
    slug: "test",
    token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
    referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
    utm_source: "whatsapp",
    data: %{
      ip: "127.0.0.1"
    }
  }

  @valid_order_attrs %{
    status: "pending",
    promotion_expires_at:
      DateTime.utc_now()
      |> DateTime.add(3600, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601(),
    cart: %{
      token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoM=",
      price_type: "promotional",
      customer_id: nil,
      visit_id: nil,
      lines: [
        %{
          name: "some name",
          quantity: 42,
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          item: %{
            name: "some name",
            visibility: "visible",
            price: Money.new(100, :ARS),
            promotional_price: Money.new(90, :ARS)
          }
        }
      ]
    }
  }
  @update_order_attrs %{
    status: "processing",
    promotion_expires_at:
      DateTime.utc_now()
      |> DateTime.add(3600, :second)
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()
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

  defp fixture(_session, :visit, attrs) do
    visit_attrs = Enum.into(attrs, @valid_visit_attrs)

    {:ok, visit} = Analytics.create_visit(visit_attrs)

    visit
  end

  defp fixture(session, :order, attrs) do
    {:ok, cart} = create_cart(session, attrs[:cart])

    order_attrs =
      attrs
      |> Enum.into(@valid_order_attrs)
      |> Map.delete(:cart)
      |> Map.put(:cart_id, cart.id)

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

    test "customer_exists?/1 returns nonexistence" do
      refute Sales.customer_exists?("123")
    end

    test "customer_exists?/1 returns existence" do
      customer = fixture(nil, :customer)

      {:ok, token} =
        Tq2.Shares.create_token(%{
          value: "hItfgIBvse62B_oZPgu6Ppp3qORvjbVCPEi9E-Poz2U=",
          customer_id: customer.id
        })

      assert Sales.customer_exists?(token.value)
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

    test "create_customer/4 with valid data creates a customer and updates cart token" do
      token = Customer.random_token()
      store = default_store()
      session = create_session()
      {:ok, cart} = create_cart(session)

      assert {:ok, %Customer{} = customer} =
               Sales.create_customer(@valid_customer_attrs, store, token, cart.token)

      assert customer.name == @valid_customer_attrs.name
      assert customer.email == Customer.canonized_email(@valid_customer_attrs.email)
      assert customer.phone == Customer.canonized_phone(@valid_customer_attrs.phone)
      assert customer.address == @valid_customer_attrs.address
      assert Tq2.Transactions.get_cart(session.account, token)
    end

    test "create_customer/4 with invalid data returns error changeset" do
      token = Customer.random_token()
      store = default_store()
      session = create_session()
      {:ok, cart} = create_cart(session)

      assert {:error, %Ecto.Changeset{}} =
               Sales.create_customer(@invalid_customer_attrs, store, token, cart.token)
    end

    test "update_customer/2 with valid data updates the customer" do
      customer = fixture(nil, :customer)

      assert {:ok, %Customer{} = customer} =
               Sales.update_customer(customer, @valid_customer_update_attrs)

      assert customer.name == @valid_customer_update_attrs.name
      assert customer.email == Customer.canonized_email(@valid_customer_update_attrs.email)
      assert customer.phone == Customer.canonized_phone(@valid_customer_update_attrs.phone)
      assert customer.address == @valid_customer_update_attrs.address
    end

    test "update_customer/2 with invalid data returns error changeset" do
      customer = fixture(nil, :customer)

      assert {:error, %Ecto.Changeset{}} =
               Sales.update_customer(customer, @invalid_customer_attrs)

      assert customer.email == Sales.get_customer!(customer.id).email
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
      account = default_account()

      {:ok, session: %Tq2.Accounts.Session{account: account}}
    end

    test "list_orders/2 returns all orders", %{session: session} do
      order = fixture(session, :order)

      assert Enum.map(Sales.list_orders(session.account, %{}).entries, & &1.id) == [order.id]
    end

    test "list_unexpired_orders/2 returns unexpired promotional orders", %{session: session} do
      visit = fixture(session, :visit)
      order = fixture(session, :order)

      _non_promotional_order =
        fixture(session, :order, %{
          cart: %{@valid_order_attrs.cart | price_type: "regular", visit_id: visit.id}
        })

      assert Enum.map(Sales.list_unexpired_orders(session.account, %{}).entries, & &1.id) == [
               order.id
             ]

      {:ok, _order} =
        Sales.update_order(session, order, %{
          promotion_expires_at: DateTime.utc_now() |> DateTime.add(-1000, :second)
        })

      assert Sales.list_unexpired_orders(session.account, %{}).entries == []
    end

    test "orders_by_status_count/2 returns counts", %{session: session} do
      visit = fixture(session, :visit)
      order = fixture(session, :order)
      _other_order = fixture(session, :order)

      non_promotional_order =
        fixture(session, :order, %{
          cart: %{@valid_order_attrs.cart | price_type: "regular", visit_id: visit.id}
        })

      assert Sales.orders_by_status_count(session.account) == [
               {order.status, order.cart.price_type, 2},
               {non_promotional_order.status, non_promotional_order.cart.price_type, 1}
             ]
    end

    test "orders_sale_amount/2 returns the amounts of sales for the period", %{session: session} do
      assert Sales.orders_sale_amount(session.account) == Money.new(0, :ARS)

      order = fixture(session, :order, %{status: "pending", data: %{paid: true}})
      {:ok, _} = session |> Sales.update_order(order, %{status: "completed"})

      assert Sales.orders_sale_amount(session.account) == Money.new(3780, :ARS)

      order =
        fixture(session, :order, %{
          status: "pending",
          cart: %{price_type: "regular"},
          data: %{paid: true}
        })

      {:ok, _} = session |> Sales.update_order(order, %{status: "completed"})

      # 3780 (first order promotional total) + 4200 (second order regular total) = 7980
      assert Sales.orders_sale_amount(session.account) == Money.new(7980, :ARS)

      _order = fixture(session, :order)

      # Only take completed orders
      assert Sales.orders_sale_amount(session.account) == Money.new(7980, :ARS)
    end

    test "get_order!/2 returns the order with given id", %{session: session} do
      order = fixture(session, :order)

      assert Sales.get_order!(session.account, order.id).id == order.id
    end

    test "get_promotional_order_for/2 returns the order on promotional status for customer", %{
      session: session
    } do
      {:ok, owner} = create_user(session)
      {:ok, cart} = create_cart(session)

      attrs =
        @valid_order_attrs
        |> Map.delete(:cart)
        |> Map.put(:cart_id, cart.id)

      assert {:ok, %Order{} = order_1} = Sales.create_order(session.account, attrs)
      {:ok, cart} = create_cart(session, %{customer_id: order_1.customer.id})

      order_2_promotion_expires_at =
        DateTime.utc_now()
        |> DateTime.add(3605, :second)
        |> DateTime.truncate(:second)
        |> DateTime.to_iso8601()

      attrs =
        @valid_order_attrs
        |> Map.delete(:cart)
        |> Map.put(:cart_id, cart.id)
        |> Map.put(:promotion_expires_at, order_2_promotion_expires_at)

      assert {:ok, %Order{} = order_2} = Sales.create_order(session.account, attrs)

      assert Sales.get_promotional_order_for(session.account, order_1.customer).id == order_1.id

      child_order = fixture(session, :order, %{ties: [%{originator_id: order_1.id}]})

      assert Sales.get_promotional_order_for(session.account, order_1.customer).id == order_2.id

      child_order = Tq2.Repo.preload(child_order, [:children, :parents])
      order_1 = Tq2.Repo.preload(order_1, [:children, :parents])

      assert Enum.empty?(order_1.parents)
      assert Enum.empty?(child_order.children)
      assert List.first(child_order.parents).id == order_1.id
      assert List.first(order_1.children).id == child_order.id

      assert_delivered_email(Email.new_order(child_order, owner))
      assert_delivered_email(Email.new_order(child_order, child_order.customer))
      assert_delivered_email(Email.promotion_confirmation(order_1))
    end

    test "get_not_referred_pending_order/1 returns the order without a referral customer", %{
      session: session
    } do
      {:ok, cart} = create_cart(session)

      attrs =
        @valid_order_attrs
        |> Map.delete(:cart)
        |> Map.put(:cart_id, cart.id)

      assert {:ok, %Order{} = order_1} = Sales.create_order(session.account, attrs)

      assert Sales.get_not_referred_pending_order(order_1.id)

      fixture(session, :order, %{ties: [%{originator_id: order_1.id}]})

      refute Sales.get_not_referred_pending_order(order_1.id)
    end

    test "get_not_referred_pending_order/1 returns the order on pending status", %{
      session: session
    } do
      {:ok, cart} = create_cart(session)

      attrs =
        @valid_order_attrs
        |> Map.delete(:cart)
        |> Map.put(:cart_id, cart.id)
        |> Map.put(:data, %{paid: true})

      assert {:ok, %Order{} = order_1} = Sales.create_order(session.account, attrs)

      assert Sales.get_not_referred_pending_order(order_1.id)

      {:ok, _} = session |> Sales.update_order(order_1, %{status: "completed"})

      refute Sales.get_not_referred_pending_order(order_1.id)
    end

    test "get_latest_order/2 returns the most recent order for a customer", %{session: session} do
      {:ok, cart} = create_cart(session)
      token = cart.customer.tokens |> List.first()

      attrs =
        @valid_order_attrs
        |> Map.delete(:cart)
        |> Map.put(:cart_id, cart.id)

      refute Sales.get_latest_order(session.account, token.value)

      {:ok, %Order{} = order} = Sales.create_order(session.account, attrs)

      assert Sales.get_latest_order(session.account, token.value).id == order.id

      {:ok, cart} = create_cart(session, %{}, cart.customer)

      attrs =
        @valid_order_attrs
        |> Map.delete(:cart)
        |> Map.put(:cart_id, cart.id)

      {:ok, %Order{} = newer_order} = Sales.create_order(session.account, attrs)

      new_date = Timex.now() |> Timex.shift(minutes: 1) |> DateTime.truncate(:second)

      newer_order
      |> Ecto.Changeset.change(%{inserted_at: new_date})
      |> Repo.update!()

      assert Sales.get_latest_order(session.account, token.value).id == newer_order.id
    end

    test "create_order/2 with valid data creates a order", %{session: session} do
      visit = fixture(session, :visit)
      attrs = Map.put(@valid_order_attrs, :cart, %{@valid_order_attrs.cart | visit_id: visit.id})

      assert {:ok, %Order{} = order} = Sales.create_order(session.account, attrs)
      assert order.status == attrs.status
      assert DateTime.to_iso8601(order.promotion_expires_at) == attrs.promotion_expires_at

      job = Exq.Mock.jobs() |> List.first()

      assert job.class == Tq2.Workers.OrdersJob
      assert job.args == [order.id]
    end

    test "create_order/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} =
               Sales.create_order(session.account, @invalid_order_attrs)
    end

    test "create_order/2 notifies to owner and customer, and associates visit", %{
      session: session
    } do
      {:ok, owner} = create_user(session)
      {:ok, cart} = create_cart(session)

      attrs =
        @valid_order_attrs
        |> Map.delete(:cart)
        |> Map.put(:cart_id, cart.id)

      assert {:ok, %Order{} = order} = Sales.create_order(session.account, attrs)

      visit = Tq2.Analytics.get_visit!(cart_id: cart.id)

      assert order.id == visit.order_id
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
      password: "123456",
      role: "owner"
    })
  end

  defp create_cart(session, attrs \\ %{}, customer \\ nil) do
    visit = fixture(session, :visit)
    customer_token = Tq2.Sales.Customer.random_token()

    {:ok, customer} =
      case customer do
        nil ->
          Sales.create_customer(%{
            name: "some name #{:random.uniform(999_999_999)}",
            email: "some#{:random.uniform(999_999_999)}@email.com",
            phone: "#{:random.uniform(999_999_999)}",
            address: "some address",
            tokens: [%{value: customer_token}]
          })

        customer ->
          {:ok, customer}
      end

    cart_attrs =
      Map.merge(
        %{
          token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoo=",
          customer_id: attrs[:customer_id] || customer.id,
          visit_id: visit.id,
          data: %{handing: "pickup"}
        },
        attrs || %{}
      )

    {:ok, cart} = Tq2.Transactions.create_cart(session.account, cart_attrs)

    {:ok, item} =
      Tq2.Inventories.create_item(session, %{
        name: "some name #{:random.uniform()}",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS)
      })

    {:ok, _line} =
      Tq2.Transactions.create_line(cart, %{
        name: "some name #{:random.uniform()}",
        quantity: 42,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        item: item
      })

    {:ok, %{cart | customer: %{customer | tokens: [%Tq2.Shares.Token{value: customer_token}]}}}
  end
end
