defmodule Tq2.Transactions.CartTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures,
    only: [
      app_mercado_pago_fixture: 0,
      create_customer: 0,
      create_session: 0,
      default_account: 0,
      default_store: 0
    ]

  describe "cart" do
    alias Tq2.Transactions.Cart

    @valid_attrs %{
      token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
      price_type: "promotional",
      account_id: "1",
      visit_id: nil
    }
    @invalid_attrs %{
      token: nil,
      price_type: nil,
      account_id: nil,
      visit_id: nil
    }

    test "changeset with valid attributes" do
      changeset = Cart.changeset(%Cart{}, @valid_attrs, default_account())

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Cart.changeset(%Cart{}, @invalid_attrs, default_account())

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:token, String.duplicate("a", 256))

      changeset = Cart.changeset(%Cart{}, attrs, default_account())

      assert "should be at most 255 character(s)" in errors_on(changeset).token
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:price_type, "xx")

      changeset = Cart.changeset(%Cart{}, attrs, default_account())

      assert "is invalid" in errors_on(changeset).price_type
    end

    test "total for promotinal price with shipping" do
      visit = create_visit()

      attrs =
        @valid_attrs
        |> Map.merge(%{
          visit_id: visit.id,
          data: %{
            handing: "delivery",
            shipping: %{name: "Anywhere", price: %Money{amount: 1000, currency: :ARS}}
          }
        })

      {:ok, cart} = default_account() |> Tq2.Transactions.create_cart(attrs)

      cart = create_line(cart)

      assert Money.new(1270, "ARS") == Cart.total(cart)
    end

    test "total for promotinal price" do
      visit = create_visit()

      {:ok, cart} =
        default_account()
        |> Tq2.Transactions.create_cart(%{@valid_attrs | visit_id: visit.id})

      cart = create_line(cart)

      assert Money.new(270, "ARS") == Cart.total(cart)
    end

    test "total for regular price" do
      visit = create_visit()

      {:ok, cart} =
        default_account()
        |> Tq2.Transactions.create_cart(%{
          @valid_attrs
          | price_type: "regular",
            visit_id: visit.id
        })

      cart = create_line(cart)

      assert Money.new(300, "ARS") == Cart.total(cart)
    end

    test "pending_amount without payment" do
      visit = create_visit()

      {:ok, cart} =
        default_account()
        |> Tq2.Transactions.create_cart(%{
          @valid_attrs
          | price_type: "regular",
            visit_id: visit.id
        })

      cart = create_line(cart)

      assert Cart.pending_amount(cart) == Cart.total(cart)
    end

    test "amount checkings with partial payment" do
      visit = create_visit()

      {:ok, cart} =
        default_account()
        |> Tq2.Transactions.create_cart(%{
          @valid_attrs
          | price_type: "regular",
            visit_id: visit.id
        })

      cart = create_line(cart)

      half = cart |> Cart.total() |> Money.multiply(0.5)

      {:ok, _payment} =
        Tq2.Payments.create_payment(
          cart,
          %{
            amount: half,
            kind: "cash",
            status: "paid"
          }
        )

      cart = Tq2.Repo.preload(cart, :payments)

      assert Cart.pending_amount(cart) == half
      assert Cart.payments_amount(cart.payments, cart) == half
      refute Cart.paid_in_full?(cart.payments, cart)
    end

    test "amount checkings with payment" do
      visit = create_visit()

      {:ok, cart} =
        default_account()
        |> Tq2.Transactions.create_cart(%{
          @valid_attrs
          | price_type: "regular",
            visit_id: visit.id
        })

      cart = create_line(cart)

      total = Cart.total(cart)

      {:ok, _payment} =
        Tq2.Payments.create_payment(
          cart,
          %{
            amount: total,
            kind: "cash",
            status: "paid"
          }
        )

      cart = Tq2.Repo.preload(cart, :payments)

      assert Cart.pending_amount(cart) == Money.new(0, total.currency)
      assert Cart.payments_amount(cart.payments, cart) == total
      assert Cart.paid_in_full?(cart.payments, cart)
    end

    test "currency for preloaded account" do
      cart = %Cart{account: %Tq2.Accounts.Account{country: "ar"}}

      assert Cart.currency(cart) == "ARS"
    end

    test "currency for preloaded lines" do
      visit = create_visit()

      {:ok, cart} =
        default_account()
        |> Tq2.Transactions.create_cart(%{
          @valid_attrs
          | price_type: "regular",
            visit_id: visit.id
        })

      cart = create_line(cart)

      assert Cart.currency(cart) == "ARS"
    end

    test "shipping/1 returns valid shipping" do
      shipping = %{name: "Anywhere", price: %Money{amount: 1000, currency: :ARS}}

      assert shipping == Cart.shipping(%Cart{data: %{shipping: shipping}})
    end

    test "shipping/1 returns nil" do
      refute Cart.shipping(%Cart{data: %{shipping: nil}})
      refute Cart.shipping(%Cart{data: %{}})
      refute Cart.shipping(%Cart{})
    end

    test "can_be_copied?/3 returns true when previous cart has _current_ information" do
      store = default_store()
      cart = %Cart{data: %Tq2.Transactions.Data{}}

      other = %Cart{
        customer: create_customer(),
        data: %Tq2.Transactions.Data{payment: "cash"}
      }

      assert Cart.can_be_copied?(store, cart, other)

      cart = %{cart | data: nil}

      assert Cart.can_be_copied?(store, cart, other)
    end

    test "can_be_copied?/3 checks shipping" do
      store = default_store()
      cart = %Cart{data: %Tq2.Transactions.Data{}}

      other = %Cart{
        customer: create_customer(),
        data: %Tq2.Transactions.Data{
          payment: "cash",
          shipping: List.first(store.configuration.shippings)
        }
      }

      assert Cart.can_be_copied?(store, cart, other)

      other = %{other | data: %Tq2.Transactions.Data{shipping: %Tq2.Shops.Shipping{id: "old"}}}

      refute Cart.can_be_copied?(store, cart, other)
    end

    test "can_be_copied?/3 checks available payment" do
      store = default_store()
      cart = %Cart{data: %Tq2.Transactions.Data{}}

      other = %Cart{
        customer: create_customer(),
        data: %Tq2.Transactions.Data{payment: "mercado_pago"}
      }

      refute Cart.can_be_copied?(store, cart, other)

      app_mercado_pago_fixture()

      assert Cart.can_be_copied?(store, cart, other)
    end

    test "can_be_copied?/3 checks customer" do
      customer = %{create_customer() | address: nil, phone: nil}
      store = default_store()
      cart = %Cart{data: %Tq2.Transactions.Data{}}

      other = %Cart{
        customer: customer,
        data: %Tq2.Transactions.Data{payment: "cash"}
      }

      refute Cart.can_be_copied?(store, cart, other)

      customer = %{customer | address: "Awesome st", phone: "555-5555"}
      other = %{other | customer: customer}

      assert Cart.can_be_copied?(store, cart, other)
    end

    test "extract_data/3 returns data map" do
      store = default_store()
      shipping = store.configuration.shippings |> List.first() |> Map.from_struct()
      cart = %Cart{data: %Tq2.Transactions.Data{id: "original"}}

      other = %Cart{
        data: %Tq2.Transactions.Data{
          id: "other",
          handing: "delivery",
          payment: "cash",
          shipping: shipping
        }
      }

      assert %{id: "original", handing: "delivery", payment: "cash", shipping: ^shipping} =
               Cart.extract_data(store, cart, other)
    end
  end

  defp create_visit do
    {:ok, visit} =
      Tq2.Analytics.create_visit(%{
        slug: "test",
        token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
        referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
        utm_source: "whatsapp",
        data: %{
          ip: "127.0.0.1"
        }
      })

    visit
  end

  defp create_line(cart) do
    session = create_session()

    {:ok, item} =
      Tq2.Inventories.create_item(session, %{
        name: "some name",
        visibility: "visible",
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS)
      })

    {:ok, _line} =
      Tq2.Transactions.create_line(cart, %{
        name: "some name",
        quantity: 3,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        item: item
      })

    Tq2.Repo.preload(cart, :lines, force: true)
  end
end
