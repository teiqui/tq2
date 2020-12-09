defmodule Tq2Web.ItemLiveTest do
  use Tq2Web.ConnCase

  import Phoenix.LiveViewTest

  @create_attrs %{
    sku: "some sku",
    name: "some name",
    description: "some description",
    visibility: "visible",
    price: Money.new(100, :ARS),
    promotional_price: Money.new(90, :ARS),
    cost: Money.new(80, :ARS),
    image: %Plug.Upload{
      content_type: "image/png",
      filename: "test.png",
      path: Path.absname("test/support/fixtures/files/test.png")
    }
  }

  def item_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    {:ok, item} = Tq2.Inventories.create_item(session, @create_attrs)

    %{item: item}
  end

  def store_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    {:ok, store} =
      Tq2.Shops.create_store(session, %{
        name: "Test store",
        slug: "test_store"
      })

    %{store: store}
  end

  describe "render" do
    setup [:item_fixture, :store_fixture]

    test "disconnected and connected render", %{conn: conn, item: item, store: store} do
      conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      {:ok, item_live, html} = live(conn, "/#{store.slug}/items/#{item.id}")

      assert html =~ item.name
      assert render(item_live) =~ item.name
    end

    test "add event", %{conn: conn, item: item, store: store} do
      conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      {:ok, item_live, _html} = live(conn, "/#{store.slug}/items/#{item.id}")

      store_path = "/#{store.slug}"

      assert {:error, {:live_redirect, %{kind: :push, to: ^store_path}}} =
               render_click(item_live, :add, %{"type" => "promotional", "id" => item.id})
    end

    test "increase event", %{conn: conn, item: item, store: store} do
      conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      {:ok, item_live, _html} = live(conn, "/#{store.slug}/items/#{item.id}")

      assert item_live
             |> element("[data-quantity]")
             |> render() =~ "1"

      assert render_click(item_live, :increase) =~ "data-quantity=\"2\""
    end

    test "decrease event", %{conn: conn, item: item, store: store} do
      conn = %{conn | host: "#{Application.get_env(:tq2, :store_subdomain)}.lvh.me"}
      {:ok, item_live, _html} = live(conn, "/#{store.slug}/items/#{item.id}")

      assert render_click(item_live, :increase) =~ "data-quantity=\"2\""
      assert render_click(item_live, :decrease) =~ "data-quantity=\"1\""
      assert render_click(item_live, :decrease) =~ "data-quantity=\"1\""
    end
  end
end
