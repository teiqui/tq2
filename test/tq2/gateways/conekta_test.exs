defmodule Tq2.Gateways.ConektaTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [conekta_app: 0, create_order: 0, default_store: 0]

  alias Tq2.Gateways.Conekta

  describe "conekta" do
    test "get_order/2 returns order" do
      with_mock Conekta, mock_get_order() do
        payment = %{} |> Conekta.get_order("ord_123")

        assert %{} = payment
        assert "ord_123" == payment["id"]
        assert "paid" == List.first(payment["charges"]["data"])["status"]
      end
    end

    test "commission_url/0 returns commission url" do
      url = Conekta.commission_url()

      assert String.contains?(url, "conekta.com/pricing")
    end

    test "create_cart_preference/3 returns a valid map preference" do
      %{order: %{cart: cart}} = create_order()
      cart = %{cart | customer: %{name: "Test"}}
      app = conekta_app()

      with_mock HTTPoison, mock_preference() do
        preference = app |> Conekta.create_cart_preference(cart, default_store())

        assert preference["id"] == "ord_123"
        assert preference["checkout"]["type"] == "HostedPayment"
        assert preference["checkout"]["url"] =~ "123asd123"
      end
    end

    test "create_cart_preference/3 returns a valid map for partial preference" do
      %{order: order} = create_order()
      cart = %{order.cart | customer: %{name: "Test"}, order: %{id: 123}}

      {:ok, payment} =
        cart
        |> Tq2.Payments.create_payment(%{
          kind: "conekta",
          status: "pending",
          amount: %Money{amount: 2000, currency: :MXN}
        })

      cart = %{cart | order: order, payments: [payment]}
      app = conekta_app()

      with_mock HTTPoison, mock_preference() do
        preference = app |> Conekta.create_cart_preference(cart, default_store())

        assert preference["id"] == "ord_123"
        assert preference["checkout"]["type"] == "HostedPayment"
        assert preference["checkout"]["url"] =~ "123asd123"
      end
    end
  end

  defp mock_get_order do
    [
      get_order: fn _app, _id ->
        %{
          "id" => "ord_123",
          "amount" => 1000,
          "currency" => "MXN",
          "payment_status" => "paid",
          "charges" => %{
            "data" => [
              %{
                "amount" => 1000,
                "currency" => "MXN",
                "order_id" => "ord_123",
                "status" => "paid"
              }
            ]
          }
        }
      end
    ]
  end

  defp mock_preference do
    [
      post: fn _url, _params, _headers ->
        body =
          Jason.encode!(%{
            "id" => "ord_123",
            "checkout" => %{
              "type" => "HostedPayment",
              "url" => "https://pay.conekta.com/checkout/123asd123"
            }
          })

        {:ok, %HTTPoison.Response{body: body, status_code: 200}}
      end
    ]
  end
end
