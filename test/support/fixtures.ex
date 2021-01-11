defmodule Tq2.Fixtures do
  import Ecto.Query
  import Tq2.Support.MercadoPagoHelper, only: [mock_check_credentials: 1]

  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, Session}

  def user_valid_attrs do
    %{
      email: "some@email.com",
      lastname: "some lastname",
      name: "some name",
      password: "123456",
      role: "owner"
    }
  end

  def user_fixture(%Session{} = session, attrs \\ %{}) do
    user_attrs = Enum.into(attrs, user_valid_attrs())

    {:ok, user} = Accounts.create_user(session, user_attrs)

    %{user | password: nil}
  end

  def default_account do
    account =
      Account
      |> where(name: "test_account")
      |> join(:left, [a], l in assoc(a, :license))
      |> preload([a, l], license: l)
      |> Tq2.Repo.one()

    %{account | license: %{account.license | account: account}}
  end

  def default_account(_) do
    {:ok, account: default_account()}
  end

  def create_session do
    %Session{account: default_account()}
  end

  def create_session(_) do
    {:ok, session: create_session()}
  end

  def create_customer(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some name",
        email: "some@email.com",
        phone: "555-5555",
        address: "some address"
      })

    {:ok, customer} = Tq2.Sales.create_customer(attrs)

    customer
  end

  def init_test_session(%{conn: conn}) do
    session = create_session()
    user = user_fixture(session)

    session = %{session | user: user}

    conn =
      conn
      |> Plug.Test.init_test_session(account_id: session.account.id, user_id: session.user.id)

    {:ok, %{conn: conn, session: session}}
  end

  def create_order(_ \\ nil) do
    session = create_session()

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
        quantity: 42,
        price: Money.new(100, :ARS),
        promotional_price: Money.new(90, :ARS),
        cost: Money.new(80, :ARS),
        item: item
      })

    cart = %{cart | lines: [line]}

    {:ok, order} =
      Tq2.Sales.create_order(
        session.account,
        %{
          cart_id: cart.id,
          promotion_expires_at: Timex.now() |> Timex.shift(days: 1),
          status: "pending"
        }
      )

    %{order: %{order | cart: cart}}
  end

  def app_mercado_pago_fixture(_ \\ nil) do
    attrs = %{
      "name" => "mercado_pago",
      "status" => "active",
      "data" => %{"access_token" => "TEST-123-asd-123"}
    }

    mock_check_credentials do
      {:ok, app} = create_session() |> Tq2.Apps.create_app(attrs)

      %{app: app}
    end
  end
end
