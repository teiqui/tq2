defmodule Tq2.PaymentsTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures, only: [create_session: 1]

  alias Tq2.Payments

  describe "payments" do
    setup [:create_session]

    alias Tq2.Payments.Payment

    @valid_attrs %{
      amount: Money.new(2000, "ARS"),
      kind: "cash",
      status: "paid"
    }
    @invalid_attrs %{
      amount: nil,
      kind: nil,
      status: nil
    }
    @valid_cart_attrs %{
      token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoM=",
      visit_id: nil
    }
    @mp_attrs %{
      amount: Money.new(2000, "ARS"),
      status: "pending",
      external_id: "tq2-mp-cart-123",
      kind: "mercado_pago"
    }

    defp cart_fixture(session) do
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

      {:ok, cart} =
        session.account |> Tq2.Transactions.create_cart(%{@valid_cart_attrs | visit_id: visit.id})

      {:ok, item} =
        Tq2.Inventories.create_item(session, %{
          sku: "some sku",
          name: "some name",
          visibility: "visible",
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          cost: Money.new(80, :ARS)
        })

      {:ok, line} =
        Tq2.Transactions.create_line(cart, %{
          name: "some name",
          quantity: 3,
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          cost: Money.new(80, :ARS),
          item: item
        })

      %{cart | lines: [line]}
    end

    defp order_fixture(account, cart) do
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

      {:ok, order} =
        Tq2.Sales.create_order(
          account,
          %{
            cart_id: cart.id,
            visit_id: visit.id,
            promotion_expires_at: DateTime.utc_now(),
            data: %{}
          }
        )

      %{order | cart: cart}
    end

    test "create_payment/2 with valid data creates a payment", %{session: session} do
      assert {:ok, %Payment{} = payment} =
               session
               |> cart_fixture()
               |> Payments.create_payment(@valid_attrs)

      assert payment.amount == @valid_attrs.amount
      assert payment.kind == @valid_attrs.kind
      assert payment.status == @valid_attrs.status
    end

    test "create_payment/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} =
               session
               |> cart_fixture()
               |> Payments.create_payment(@invalid_attrs)
    end

    test "update_payment_by_external_id/2 with valid data update payment create order", %{
      session: session
    } do
      assert {:ok, %Payment{} = original_payment} =
               session
               |> cart_fixture()
               |> Payments.create_payment(@mp_attrs)

      original_payment = Tq2.Repo.preload(original_payment, :order, force: true)

      refute original_payment.order

      assert {:ok, payment} =
               Payments.update_payment_by_external_id(
                 %{
                   external_id: @mp_attrs.external_id,
                   status: "paid"
                 },
                 session.account
               )

      assert payment.status == "paid"
      assert payment.order.id
      assert payment.order.data.paid
    end

    test "update_payment_by_external_id/2 with valid data update payment with order", %{
      session: session
    } do
      cart = session |> cart_fixture()

      assert {:ok, %Payment{} = original_payment} = cart |> Payments.create_payment(@mp_attrs)

      assert order_fixture(session.account, cart)

      original_payment = Tq2.Repo.preload(original_payment, :order, force: true)

      assert original_payment.order
      refute original_payment.order.data.paid

      assert {:ok, payment} =
               Payments.update_payment_by_external_id(
                 %{
                   external_id: @mp_attrs.external_id,
                   status: "paid"
                 },
                 session.account
               )

      assert payment.status == "paid"
      assert payment.order.id == original_payment.order.id
      assert payment.order.data.paid
    end

    test "get_pending_payment_for_cart_and_kind/2 returns nil for unknown payment", %{
      session: session
    } do
      cart = session |> cart_fixture()

      refute Payments.get_pending_payment_for_cart_and_kind(cart, "cash")
    end

    test "get_pending_payment_for_cart_and_kind/2 returns payment for kind", %{session: session} do
      cart = session |> cart_fixture()

      attrs =
        @valid_attrs
        |> Map.put(:status, "pending")
        |> Map.put(:kind, "transbank")

      {:ok, payment} = cart |> Payments.create_payment(attrs)

      assert Payments.get_pending_payment_for_cart_and_kind(cart, "transbank").id == payment.id
    end

    test "get_pending_payment_for_cart_and_kind/2 returns nil for paid payment", %{
      session: session
    } do
      cart = session |> cart_fixture()

      {:ok, _payment} = cart |> Payments.create_payment(@valid_attrs)

      refute Payments.get_pending_payment_for_cart_and_kind(cart, "cash")
    end

    test "update_payment/2 returns updated payment", %{
      session: session
    } do
      cart = session |> cart_fixture()

      {:ok, payment} = cart |> Payments.create_payment(@valid_attrs)

      assert {:ok, payment} =
               cart
               |> Payments.update_payment(
                 payment,
                 %{status: "pending", gateway_data: %{"key" => "value"}}
               )

      assert payment.status == "pending"
      assert payment.gateway_data == %{"key" => "value"}
    end

    test "get_payment_by_external_id/1 returns payment", %{session: session} do
      cart = session |> cart_fixture()
      attrs = @valid_attrs |> Map.put(:external_id, "asd_123")

      {:ok, original_payment} = cart |> Payments.create_payment(attrs)

      payment = Payments.get_payment_by_external_id("asd_123")

      assert payment.id == original_payment.id
    end
  end
end
