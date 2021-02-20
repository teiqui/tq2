defmodule Tq2Web.Store.PaymentControllerTest do
  use Tq2Web.ConnCase

  import Mock
  import Tq2.Fixtures, only: [default_store: 0, create_cart: 0, transbank_app: 0]

  setup %{conn: conn} do
    conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.localhost"}

    {:ok, %{conn: conn, store: default_store()}}
  end

  describe "transbank without token" do
    setup [:setup_transbank]

    test "respond empty json without token", %{conn: conn, store: store} do
      path = Routes.transbank_payment_path(conn, :transbank, store, %{"channel" => "WEB"})
      conn = post(conn, path)
      empty_map = %{}

      assert ^empty_map = json_response(conn, 200)
    end
  end

  describe "transbank with token" do
    setup [:setup_cart, :setup_transbank]

    test "respond empty json without payment", %{conn: conn, store: store} do
      path = Routes.transbank_payment_path(conn, :transbank, store, %{"channel" => "WEB"})
      conn = post(conn, path)
      empty_map = %{}

      assert ^empty_map = json_response(conn, 200)
    end

    test "respond with payment gateway info", %{conn: conn, cart: cart, store: store} do
      {:ok, _payment} =
        cart
        |> Tq2.Payments.create_payment(%{
          kind: "transbank",
          status: "pending",
          amount: %Money{amount: 2000, currency: :CLP}
        })

      path = Routes.transbank_payment_path(conn, :transbank, store, %{"channel" => "WEB"})

      attrs = %{
        "responseCode" => "OK",
        "result" => %{
          "externalUniqueNumber" => "123"
        }
      }

      mock = [create_cart_preference: fn _app, _cart, _store, _channel -> attrs end]

      with_mock Tq2.Gateways.Transbank, mock do
        conn = post(conn, path)

        assert %{"amount" => 2000, "externalUniqueNumber" => "123"} = json_response(conn, 200)

        payment = Tq2.Payments.get_payment!(store.account, "123")

        assert payment.gateway_data["externalUniqueNumber"] == "123"
      end
    end
  end

  def setup_cart(%{conn: conn}) do
    cart = create_cart()
    conn = conn |> Plug.Test.init_test_session(token: cart.token)

    {:ok, %{cart: cart, conn: conn}}
  end

  defp setup_transbank(_) do
    transbank_app()

    {:ok, %{}}
  end
end
