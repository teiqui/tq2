defmodule Tq2Web.Store.PaymentControllerTest do
  use Tq2Web.ConnCase

  import Mock
  import Tq2.Fixtures, only: [default_store: 0, create_cart: 0, transbank_app: 0]

  alias Tq2.Transactions
  alias Tq2.Transactions.Cart

  setup %{conn: conn} do
    conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}

    {:ok, %{conn: conn, store: default_store()}}
  end

  describe "transbank" do
    setup [:setup_cart, :setup_transbank]

    test "respond empty json without payment", %{conn: conn, cart: cart, store: store} do
      path =
        Routes.transbank_payment_path(conn, :transbank, store, %{
          channel: "WEB",
          id: cart.id
        })

      conn = post(conn, path)
      empty_map = %{}

      assert ^empty_map = json_response(conn, 200)
    end

    test "respond with payment gateway info", %{conn: conn, cart: cart, store: store} do
      # Promo payment
      total = cart |> Cart.total()

      {:ok, _payment} =
        cart
        |> Tq2.Payments.create_payment(%{
          kind: "transbank",
          status: "pending",
          amount: total
        })

      path =
        Routes.transbank_payment_path(conn, :transbank, store, %{
          channel: "WEB",
          id: cart.id
        })

      attrs = %{
        "responseCode" => "OK",
        "result" => %{
          "externalUniqueNumber" => "123"
        }
      }

      mock = [create_cart_preference: fn _app, _cart, _store, _channel -> attrs end]

      with_mock Tq2.Gateways.Transbank, mock do
        conn = post(conn, path)

        response = json_response(conn, 200)

        assert total.amount == response["amount"]
        assert "123" == response["externalUniqueNumber"]

        payment = Tq2.Payments.get_payment!(store.account, "123")

        assert payment.gateway_data["externalUniqueNumber"] == "123"

        {:ok, _payment} = cart |> Tq2.Payments.update_payment(payment, %{status: "paid"})
      end

      # Partial payment
      {:ok, _cart} = store.account |> Transactions.update_cart(cart, %{price_type: "regular"})

      cart = Transactions.get_cart!(store.account, cart.id)

      refute Cart.paid?(cart)

      pending = cart |> Cart.pending_amount()

      assert pending < total

      {:ok, _payment} =
        cart
        |> Tq2.Payments.create_payment(%{
          kind: "transbank",
          status: "pending",
          amount: pending
        })

      path =
        Routes.transbank_payment_path(conn, :transbank, store, %{
          channel: "WEB",
          id: cart.id
        })

      attrs = %{
        "responseCode" => "OK",
        "result" => %{
          "externalUniqueNumber" => "124"
        }
      }

      mock = [create_partial_preference: fn _app, _cart, _store, _channel -> attrs end]

      with_mock Tq2.Gateways.Transbank, mock do
        conn = post(conn, path)

        response = json_response(conn, 200)

        assert pending.amount == response["amount"]
        assert "124" == response["externalUniqueNumber"]

        payment = Tq2.Payments.get_payment!(store.account, "124")

        assert payment.gateway_data["externalUniqueNumber"] == "124"

        {:ok, _payment} = cart |> Tq2.Payments.update_payment(payment, %{status: "paid"})
      end

      cart = Transactions.get_cart!(store.account, cart.id)

      assert Cart.paid?(cart)
    end
  end

  def setup_cart(%{conn: conn}) do
    cart = create_cart()

    {:ok, %{cart: cart, conn: conn}}
  end

  defp setup_transbank(_) do
    transbank_app()

    {:ok, %{}}
  end
end
