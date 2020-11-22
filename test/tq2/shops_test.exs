defmodule Tq2.ShopsTest do
  use Tq2.DataCase

  alias Tq2.Shops

  describe "stores" do
    setup [:create_session]

    alias Tq2.Shops.Store

    @valid_attrs %{
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
        delivery: true,
        delivery_area: "some delivery area",
        delivery_time_limit: "some time limit",
        pay_on_delivery: true
      },
      data: %{
        address: "some address",
        phone: "some phone",
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

    defp create_session(_) do
      account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")

      {:ok, session: %Tq2.Accounts.Session{account: account}}
    end

    defp fixture(session, :store, attrs \\ %{}) do
      store_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, store} = Shops.create_store(session, store_attrs)

      store
    end

    test "get_store!/1 returns the store for given account", %{session: session} do
      store = fixture(session, :store)

      assert Shops.get_store!(session.account) == store
    end

    test "create_store/2 with valid data creates a store", %{session: session} do
      assert {:ok, %Store{} = store} = Shops.create_store(session, @valid_attrs)
      assert store.name == @valid_attrs.name
      assert store.description == @valid_attrs.description
      assert store.slug == @valid_attrs.slug
      assert store.published == @valid_attrs.published

      url =
        {store.logo, store}
        |> Tq2.LogoUploader.url(:original)
        |> String.replace(~r(\?.*), "")

      path = Path.absname("priv/waffle/private#{url}")

      assert File.exists?(path)
    end

    test "create_store/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} = Shops.create_store(session, @invalid_attrs)
    end

    test "update_store/3 with valid data updates the store", %{session: session} do
      store = fixture(session, :store)

      assert {:ok, store} = Shops.update_store(session, store, @update_attrs)
      assert %Store{} = store
      assert store.name == @update_attrs.name
      assert store.description == @update_attrs.description
      assert store.slug == @update_attrs.slug
      assert store.published == @update_attrs.published
    end

    test "update_store/3 with invalid data returns error changeset", %{session: session} do
      store = fixture(session, :store)

      assert {:error, %Ecto.Changeset{}} = Shops.update_store(session, store, @invalid_attrs)
      assert store == Shops.get_store!(session.account)
    end

    test "change_store/2 returns a store changeset", %{session: session} do
      store = fixture(session, :store)

      assert %Ecto.Changeset{} = Shops.change_store(session.account, store)
    end
  end
end
