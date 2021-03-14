defmodule Tq2.Gateways.MercadoPagoTest do
  use Tq2.DataCase

  import Mock

  import Tq2.Fixtures,
    only: [
      app_mercado_pago_fixture: 0,
      create_session: 0,
      default_store: 0
    ]

  alias Tq2.Gateways.MercadoPago
  alias Tq2.Gateways.MercadoPago.Credential
  alias Tq2.Sales.Order

  describe "mercado pago" do
    @default_payment %{
      id: 123,
      external_reference: "123",
      transaction_amount: 12.0,
      date_approved: Timex.now(),
      status: "approved",
      currency_id: "ARS"
    }
    @credential %Credential{token: "123-asd-123"}

    test "min_amount_for/1 returns min amount for currency" do
      assert 2.0 == MercadoPago.min_amount_for("ARS")
      assert 1000.0 == MercadoPago.min_amount_for("COP")
    end

    test "get_payment/2 returns payment" do
      with_mock HTTPoison, mock_get_with() do
        payment = @credential |> MercadoPago.get_payment("123")

        assert %{} = payment
        assert 123 == payment["id"]
        assert "approved" == payment["status"]
      end
    end

    test "last_payment_for_reference/2 returns parsed payment" do
      mocked_fn = %{"results" => [@default_payment]} |> mock_get_with()

      with_mock HTTPoison, mocked_fn do
        payment =
          @credential
          |> MercadoPago.last_payment_for_reference(@default_payment.external_reference)

        assert %{} = payment
        assert "123" == payment.external_id
        assert "paid" == payment.status
        assert %DateTime{} = payment.paid_at
        assert Money.new(1200, :ARS) == payment.amount
      end
    end

    test "commission_url_for/1 returns commission url" do
      session = create_session()
      url = session.account.country |> MercadoPago.commission_url_for()

      assert String.contains?(url, "mercadopago.com.ar")
      assert String.contains?(url, "costo-recibir-pagos")
    end

    test "create_cart_preference/1 returns a valid map preference" do
      session = create_session()
      cart = session.account |> create_cart_with_line()
      %{app: app} = app_mercado_pago_fixture()

      default_preference = %{
        id: 33,
        external_reference: "tq2-mp-cart-#{cart.id}",
        init_point: "https://mp.com/123"
      }

      mocked_fn = default_preference |> mock_post_with()

      with_mock HTTPoison, mocked_fn do
        preference =
          %Credential{token: app.data.access_token}
          |> MercadoPago.create_cart_preference(cart, default_store())

        assert default_preference.id == preference["id"]
        assert default_preference.external_reference == preference["external_reference"]
        assert default_preference.init_point == preference["init_point"]
      end
    end

    test "create_partial_cart_preference/2 returns a valid map preference" do
      session = create_session()
      cart = session.account |> create_cart_with_line()
      cart = %{cart | order: %Order{id: 123}}
      %{app: app} = app_mercado_pago_fixture()

      default_preference = %{
        id: 33,
        external_reference: "tq2-mp-cart-#{cart.id}",
        init_point: "https://mp.com/123"
      }

      mocked_fn = default_preference |> mock_post_with()

      with_mock HTTPoison, mocked_fn do
        preference =
          %Credential{token: app.data.access_token}
          |> MercadoPago.create_partial_cart_preference(cart, default_store())

        assert default_preference.id == preference["id"]
        assert default_preference.external_reference == preference["external_reference"]
        assert default_preference.init_point == preference["init_point"]
      end
    end

    defp mock_get_with(%{} = body \\ @default_payment, code \\ 200) do
      json_body = body |> Jason.encode!()

      [
        get: fn _url, _headers ->
          {:ok, %HTTPoison.Response{status_code: code, body: json_body}}
        end
      ]
    end

    defp mock_post_with(%{} = body, code \\ 201) do
      json_body = body |> Jason.encode!()

      [
        post: fn _url, _params, _headers ->
          {:ok, %HTTPoison.Response{status_code: code, body: json_body}}
        end
      ]
    end

    defp create_cart_with_line(account) do
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

      {:ok, customer} =
        Tq2.Sales.create_customer(%{
          name: "some name",
          email: "some@email.com",
          phone: "555-5555",
          address: "some address"
        })

      cart_attrs = %{
        token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
        price_type: "promotional",
        account_id: account.id,
        customer_id: customer.id,
        visit_id: visit.id
      }

      {:ok, cart} = account |> Tq2.Transactions.create_cart(cart_attrs)

      line_attrs = %{
        name: "some name",
        quantity: 1,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cart_id: cart.id,
        item: %Tq2.Inventories.Item{
          name: "some name",
          description: "some description",
          visibility: "visible",
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          account_id: account.id
        }
      }

      {:ok, line} = cart |> Tq2.Transactions.create_line(line_attrs)

      %{cart | lines: [line], customer: customer}
    end
  end
end
