defmodule Tq2.Gateways.TransbankTest do
  use Tq2.DataCase

  import Mock
  import Tq2.Fixtures, only: [create_cart: 0, default_store: 0]

  alias Tq2.Gateways.Transbank

  describe "transbank" do
    test "create_cart_preference/3 request with correct signature" do
      app = app()
      cart = %{create_cart() | id: 20530}
      store = default_store()

      attrs = %{
        "responseCode" => "OK",
        "result" => %{
          "externalUniqueNumber" => "123"
        }
      }

      mock = [
        post: fn _url, params, _headers ->
          signature =
            params
            |> Jason.decode!()
            |> Map.get("signature")

          assert signature == "p2ma+PBjGlTpT+c8VZrlKz5knGmAeaBp60QKrsm38B4="

          {:ok, %HTTPoison.Response{body: Jason.encode!(attrs), status_code: 200}}
        end
      ]

      timestamp_mock = [timestamp: fn -> 1_613_349_864 end]

      with_mock Transbank, [:passthrough], timestamp_mock do
        with_mock HTTPoison, mock do
          result = Transbank.create_cart_preference(app, cart, store)

          assert result["responseCode"] == "OK"
          assert result["result"]["externalUniqueNumber"] == "123"
        end
      end
    end

    test "confirm_preference/2 confirm with correct signature" do
      app = app()

      attrs = %{
        "responseCode" => "OK",
        "result" => %{
          "occ" => "3333",
          "externalUniqueNumber" => "123"
        }
      }

      payment = %{gateway_data: attrs["result"]}

      mock = [
        post: fn _url, params, _headers ->
          signature =
            params
            |> Jason.decode!()
            |> Map.get("signature")

          assert signature == "UfRk6BzERkO0YCrx4uosAFdrQ3SH+16CKnz8ixpycHg="

          body =
            Jason.encode!(%{
              responseCode: "OK",
              result: %{
                occ: "3333",
                authorizationCode: "768136",
                transactionDesc: "Venta normal sin cuotas"
              }
            })

          {:ok, %HTTPoison.Response{body: body, status_code: 200}}
        end
      ]

      timestamp_mock = [timestamp: fn -> 1_613_349_864 end]

      with_mock Transbank, [:passthrough], timestamp_mock do
        with_mock HTTPoison, mock do
          result = Transbank.confirm_preference(app, payment)

          assert result["responseCode"] == "OK"
          assert result["result"]["occ"] == "3333"
        end
      end
    end

    test "response_to_payment/2 return error" do
      result = Transbank.response_to_payment(%{"description" => "Something wrong"}, %{})

      assert %{error: "Something wrong"} == result
    end

    test "response_to_payment/2 return cancelled payment attrs" do
      result =
        Transbank.response_to_payment(
          %{
            "responseCode" => "INVALID_TRANSACTION",
            "description" => "Something wrong"
          },
          %{external_id: "123"}
        )

      assert %{external_id: "123", status: "cancelled", error: "Something wrong"} == result
    end

    test "response_to_payment/2 return paid payment attrs" do
      issued_at = System.os_time(:second)

      result =
        Transbank.response_to_payment(
          %{
            "responseCode" => "OK",
            "result" => %{"issuedAt" => issued_at}
          },
          %{external_id: "123"}
        )

      assert %{external_id: "123", status: "paid", paid_at: DateTime.from_unix!(issued_at)} ==
               result
    end
  end

  defp app do
    # TODO: Change for a real Transbank app
    %{data: %{api_key: "123", shared_secret: "312"}}
  end
end
