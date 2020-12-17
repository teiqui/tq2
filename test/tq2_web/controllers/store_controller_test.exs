defmodule Tq2Web.StoreControllerTest do
  use Tq2Web.ConnCase
  use Tq2.Support.LoginHelper

  @create_attrs %{
    name: "some name",
    description: "some description",
    slug: "some_slug",
    published: true,
    logo: %Plug.Upload{
      content_type: "image/png",
      filename: "test.png",
      path: Path.absname("test/support/fixtures/files/test.png")
    },
    configuration: %{
      require_email: true,
      require_phone: true,
      pickup: true,
      pickup_time_limit: "some time limit",
      address: "some address",
      delivery: true,
      delivery_area: "some delivery area",
      delivery_time_limit: "some time limit",
      pay_on_delivery: true
    },
    data: %{
      phone: "555-5555",
      email: "some@email.com",
      whatsapp: "some whatsapp",
      facebook: "some facebook",
      instagram: "some instagram"
    },
    location: %{
      latitude: "12",
      longitude: "123"
    }
  }
  @update_attrs %{
    name: "some updated name",
    description: "some updated description",
    slug: "some_updated_slug",
    published: true,
    logo: %Plug.Upload{
      content_type: "image/png",
      filename: "test.png",
      path: Path.absname("test/support/fixtures/files/test.png")
    }
  }
  @invalid_attrs %{
    name: nil,
    description: nil,
    slug: nil,
    published: nil,
    logo: nil
  }

  def store_fixture(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
    session = %Tq2.Accounts.Session{account: account}

    {:ok, store} = Tq2.Shops.create_store(session, @create_attrs)

    %{store: store}
  end

  describe "unauthorized access" do
    test "requires user authentication on all actions", %{conn: conn} do
      Enum.each(
        [
          get(conn, Routes.store_path(conn, :show)),
          get(conn, Routes.store_path(conn, :new)),
          post(conn, Routes.store_path(conn, :create)),
          get(conn, Routes.store_path(conn, :edit)),
          put(conn, Routes.store_path(conn, :update))
        ],
        fn conn ->
          assert html_response(conn, 302)
          assert conn.halted
        end
      )
    end
  end

  describe "new store" do
    @tag login_as: "test@user.com"
    test "renders form", %{conn: conn} do
      conn = get(conn, Routes.store_path(conn, :new))

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "create store" do
    @tag login_as: "test@user.com"
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, Routes.store_path(conn, :create), store: @create_attrs

      assert redirected_to(conn) == Routes.store_path(conn, :edit)
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.store_path(conn, :create), store: @invalid_attrs

      assert html_response(conn, 200) =~ "Create"
    end
  end

  describe "show with no store" do
    @tag login_as: "test@user.com"
    test "show store", %{conn: conn} do
      conn = get(conn, Routes.store_path(conn, :show))

      assert redirected_to(conn) == Routes.store_path(conn, :new)
    end
  end

  describe "show" do
    setup [:store_fixture]

    @tag login_as: "test@user.com"
    test "show store", %{conn: conn} do
      conn = get(conn, Routes.store_path(conn, :show))

      assert redirected_to(conn) == Routes.store_path(conn, :edit)
    end
  end

  describe "edit store" do
    setup [:store_fixture]

    @tag login_as: "test@user.com"
    test "renders form for editing chosen store", %{conn: conn} do
      conn = get(conn, Routes.store_path(conn, :edit))

      assert html_response(conn, 200) =~ "Update"
    end
  end

  describe "update store" do
    setup [:store_fixture]

    @tag login_as: "test@user.com"
    test "redirects when data is valid", %{conn: conn} do
      conn = put conn, Routes.store_path(conn, :update), store: @update_attrs

      assert redirected_to(conn) == Routes.store_path(conn, :edit)
    end

    @tag login_as: "test@user.com"
    test "renders errors when data is invalid", %{conn: conn} do
      conn = put conn, Routes.store_path(conn, :update), store: @invalid_attrs

      assert html_response(conn, 200) =~ "Update"
    end
  end
end
