defmodule Tq2Web.OrderViewTest do
  use Tq2Web.ConnCase, async: true
  use Tq2.Support.LoginHelper

  import Phoenix.HTML, only: [safe_to_string: 1]
  import Phoenix.View

  alias Tq2.Payments.Payment
  alias Tq2.Sales.{Customer, Order}
  alias Tq2.Transactions.{Cart, Line}
  alias Tq2Web.OrderView

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  @tag login_as: "test@user.com"
  test "renders index.html", %{conn: conn} do
    orders = [order()]
    page = %Scrivener.Page{total_pages: 1, page_number: 1}

    content = render_to_string(OrderView, "index.html", conn: conn, orders: orders, page: page)

    assert String.contains?(content, "Pending")
    assert String.contains?(content, "Pickup")
    assert String.contains?(content, "#1")
    assert String.contains?(content, "Sample")
  end

  @tag login_as: "test@user.com"
  test "renders empty.html", %{conn: conn} do
    page = %Scrivener.Page{total_entries: 0}

    content = render_to_string(OrderView, "empty.html", conn: conn, page: page)

    assert String.contains?(content, "at this time there is none")
  end

  @tag login_as: "test@user.com"
  test "renders show.html", %{conn: conn} do
    content = render_to_string(OrderView, "show.html", conn: conn, order: order())

    assert String.contains?(content, "Order #1")
    assert String.contains?(content, "Pending")
    assert String.contains?(content, "Pickup")
    assert String.contains?(content, "line1")
    assert String.contains?(content, "$1.80")
    assert String.contains?(content, "MercadoPago")
    assert String.contains?(content, "exclamation-triangle")
  end

  @tag login_as: "test@user.com"
  test "link to show", %{conn: conn} do
    order = order()

    content = conn |> OrderView.link_to_show(order) |> safe_to_string()

    assert String.contains?(content, "#{order.id}")
    assert String.contains?(content, "href")
  end

  defp order() do
    %Order{
      id: 1,
      status: "pending",
      promotion_expires_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      inserted_at: Timex.now(),
      customer: %Customer{name: "Sample"},
      cart: %Cart{
        id: 1,
        data: %{handing: "pickup"},
        lines: [
          %Line{
            name: "line1",
            quantity: 2,
            price: Money.new(100, "ARS"),
            promotional_price: Money.new(90, "ARS")
          }
        ],
        payments: [
          %Payment{
            kind: "mercado_pago",
            status: "pending",
            amount: Money.new(180, "ARS"),
            inserted_at: Timex.now()
          }
        ]
      }
    }
  end
end
