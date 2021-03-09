defmodule Tq2.Gateways.ConektaTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [create_cart: 0, default_store: 0]

  alias Tq2.Gateways.Conekta

  describe "conekta" do
    test "get_order/2 returns order" do
      with_mock Conekta, mock_get_order() do
        payment = %{} |> Conekta.get_order("123")

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
      cart = %{create_cart() | customer: %{name: "Test"}}

      # TODO: Change for real app
      app = %{name: "conekta", data: %{api_key: "123"}}

      with_mock HTTPoison, mock_preference() do
        preference = app |> Conekta.create_cart_preference(cart, default_store())

        assert preference["id"] == "123asd123"
        assert preference["type"] == "PaymentLink"
        assert preference["url"] =~ "123asd123"
      end
    end

    test "create_partial_preference/3 returns a valid map preference" do
      cart = %{create_cart() | customer: %{name: "Test"}, order: %{id: 123}}

      {:ok, payment} =
        cart
        |> Tq2.Payments.create_payment(%{
          kind: "conekta",
          status: "pending",
          amount: %Money{amount: 2000, currency: :MXN}
        })

      payment = %{payment | cart: cart}

      # TODO: Change for real app
      app = %{name: "conekta", data: %{api_key: "123"}}

      with_mock HTTPoison, mock_preference() do
        preference = app |> Conekta.create_partial_preference(payment, default_store())

        assert preference["id"] == "123asd123"
        assert preference["type"] == "PaymentLink"
        assert preference["url"] =~ "123asd123"
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
            "id" => "123asd123",
            "type" => "PaymentLink",
            "url" => "https://pay.conekta.com/link/123asd123"
          })

        {:ok, %HTTPoison.Response{body: body, status_code: 200}}
      end
    ]
  end
end
