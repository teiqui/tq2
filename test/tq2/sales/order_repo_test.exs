defmodule Tq2.Sales.OrderRepoTest do
  use Tq2.DataCase
  import Tq2.Fixtures, only: [create_session: 0, create_customer: 0]

  alias Tq2.Accounts
  alias Tq2.Sales.Order

  @valid_attrs %{
    status: "pending",
    cart_id: 1,
    promotion_expires_at: Timex.now() |> Timex.shift(days: 1)
  }

  defp session_fixture(_) do
    %{session: create_session()}
  end

  defp user_fixture(%{session: session}) do
    {:ok, user} =
      Accounts.create_user(session, %{
        email: "some@email.com",
        lastname: "some lastname",
        name: "some name",
        password: "123456",
        role: "owner"
      })

    %{user: %{user | password: nil}}
  end

  def order_fixture(%{session: session}) do
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
      Tq2.Transactions.create_cart(session.account, %{
        token: "sdWrbLgHMK9TZGIt1DcgUcpjsukMUCs4pTKTCiEgWoo=",
        customer_id: create_customer().id,
        visit_id: visit.id,
        data: %{handing: "pickup"}
      })

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
        quantity: 42,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        item: item
      })

    {:ok, order} = Tq2.Sales.create_order(session.account, %{@valid_attrs | cart_id: cart.id})

    %{order: order}
  end

  describe "order" do
    setup [:session_fixture, :user_fixture, :order_fixture]

    alias Tq2.Notifications.Email

    test "notify", %{user: owner, order: order} do
      {:ok, order} = Order.notify({:ok, order})

      email_owner = Email.new_order(order, owner)
      email_customer = Email.new_order(order, order.customer)
      jobs = Exq.Mock.jobs() |> Enum.filter(&(&1.class == Tq2.Workers.MailerJob))

      assert Enum.any?(jobs, &(List.first(&1.args).private == email_owner.private))
      assert Enum.any?(jobs, &(List.first(&1.args).private == email_customer.private))
    end
  end
end
