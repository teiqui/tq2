defmodule Tq2.Gateways.MercadoPagoTest do
  use Tq2.DataCase

  import Mock

  alias Tq2.Gateways.MercadoPago
  alias Tq2.Gateways.MercadoPago.Credential
  import Tq2.Fixtures, only: [user_fixture: 1, create_session: 0]

  describe "mercado pago" do
    @default_payment %{
      id: 123,
      external_reference: "123",
      transaction_amount: 12.0,
      date_approved: Timex.now(),
      status: "approved",
      currency_id: "ARS"
    }
    @credential Credential.for_currency("ARS")

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

    test "marketplace_association_link/1 returns valid url" do
      link = @credential |> MercadoPago.marketplace_association_link()
      mp_link = app_uri() |> Tq2Web.Router.Helpers.mp_marketplace_url(:show)

      assert link =~ "https://auth.mercadopago.com.ar"
      # token app_id
      assert link =~ "client_id=3333"
      assert link =~ "redirect_uri=#{mp_link}"
    end

    test "associate_marketplace/2 returns valid marketplace map" do
      default_marketplace = %{
        access_token: "MARKETPLACE_SELLER_TOKEN",
        public_key: "PUBLIC_KEY",
        refresh_token: "TG-XXXXXXXXX-XXXXX",
        live_mode: true,
        user_id: "123",
        token_type: "bearer",
        expires_in: 15_552_000,
        scope: "offline_access payments write"
      }

      mocked_fn = default_marketplace |> mock_post_with()

      with_mock HTTPoison, mocked_fn do
        marketplace = @credential |> MercadoPago.associate_marketplace("111")

        assert %{} = marketplace
        assert default_marketplace.access_token == marketplace["access_token"]
        assert default_marketplace.refresh_token == marketplace["refresh_token"]
      end
    end

    test "create_license_preference/1 returns a valid map preference" do
      session = create_session()
      session |> user_fixture()

      default_preference = %{
        id: 33,
        external_reference: "123-321",
        init_point: "https://mp.com/123"
      }

      mocked_fn = default_preference |> mock_post_with()

      with_mock HTTPoison, mocked_fn do
        preference = session.account |> MercadoPago.create_license_preference()

        assert default_preference.id == preference["id"]
        assert default_preference.external_reference == preference["external_reference"]
        assert default_preference.init_point == preference["init_point"]
      end
    end

    test "update_license_with_last_payment/1 returns true until payments" do
      mocked_fn = %{results: [@default_payment]} |> mock_get_with()
      session = create_session()

      with_mock HTTPoison, mocked_fn do
        {:ok, payment} = MercadoPago.update_license_with_last_payment(session.account)

        assert payment.id
        assert payment.status == "paid"
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
      app = session |> create_mp_app()

      {:ok, store} =
        Tq2.Shops.create_store(session, %{
          name: "Test store",
          slug: "test_store",
          configuration: %{pickup: true, pickup_time_limit: "1h"}
        })

      default_preference = %{
        id: 33,
        external_reference: "tq2-cart-#{cart.id}",
        init_point: "https://mp.com/123"
      }

      mocked_fn = default_preference |> mock_post_with()

      with_mock HTTPoison, mocked_fn do
        preference =
          %Credential{token: app.data["access_token"]}
          |> MercadoPago.create_cart_preference(cart, store)

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
        customer_id: customer.id
      }

      {:ok, cart} = account |> Tq2.Transactions.create_cart(cart_attrs)

      line_attrs = %{
        name: "some name",
        quantity: 1,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS),
        cart_id: cart.id,
        item: %Tq2.Inventories.Item{
          sku: "some sku",
          name: "some name",
          description: "some description",
          visibility: "visible",
          price: Money.new(100, :ARS),
          promotional_price: Money.new(90, :ARS),
          cost: Money.new(80, :ARS),
          account_id: account.id
        }
      }

      {:ok, line} = cart |> Tq2.Transactions.create_line(line_attrs)

      %{cart | lines: [line], customer: customer}
    end

    defp create_mp_app(session) do
      attrs = %{
        name: "mercado_pago",
        data: %{
          "access_token" => "123"
        }
      }

      {:ok, app} = session |> Tq2.Apps.create_app(attrs)

      app
    end

    defp app_uri do
      scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
      url_config = Tq2Web.Endpoint.config(:url)

      %URI{
        scheme: scheme,
        host: Enum.join([Application.get_env(:tq2, :app_subdomain), url_config[:host]], ".")
      }
    end
  end
end
