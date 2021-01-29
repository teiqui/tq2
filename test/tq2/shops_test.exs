defmodule Tq2.ShopsTest do
  use Tq2.DataCase

  import Tq2.Fixtures, only: [create_session: 1, default_store: 1, default_store: 0]

  alias Tq2.Accounts
  alias Tq2.Shops

  describe "stores" do
    setup [:create_session]

    alias Tq2.Shops.Store

    @valid_attrs %{
      name: "some name",
      description: "some description",
      slug: "other_slug",
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
        pay_on_delivery: true,
        shippings: %{"0" => %{"name" => "Anywhere", "price" => "10.00"}}
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

    test "get_store!/1 returns the store for given account", %{session: session} do
      store = default_store()

      assert Shops.get_store!(session.account).id == store.id
    end

    test "get_store!/1 returns the store for given account even if not published", %{
      session: session
    } do
      store = default_store(%{published: false})

      assert Shops.get_store!(session.account).id == store.id
    end

    test "get_store!/1 returns the store for given slug" do
      store = default_store()

      assert Shops.get_store!(store.slug).id == store.id
    end

    test "get_store!/1 raises not found when the store for given slug is not published" do
      store = default_store(%{published: false})

      assert_raise Ecto.NoResultsError, fn ->
        Shops.get_store!(store.slug)
      end
    end

    test "get_store/1 returns the store for given account", %{session: session} do
      store = default_store()

      assert Shops.get_store(session.account).id == store.id
    end

    test "get_store!/1 raises not found when the store for given slug is locked", %{
      session: session
    } do
      store = default_store()

      paid_until = Date.utc_today() |> Timex.shift(days: -15)

      {:ok, _} =
        Accounts.update_license(session.account.license, %{
          status: "locked",
          paid_until: paid_until
        })

      assert_raise Ecto.NoResultsError, fn ->
        Shops.get_store!(store.slug)
      end
    end

    test "create_store/2 with valid data creates a store", %{session: session} do
      # delete default store
      {:ok, _} = default_store() |> Tq2.Repo.delete()

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
      store = default_store()

      assert {:ok, store} = Shops.update_store(session, store, @update_attrs)
      assert %Store{} = store
      assert store.name == @update_attrs.name
      assert store.description == @update_attrs.description
      assert store.slug == @update_attrs.slug
      assert store.published == @update_attrs.published
    end

    test "update_store/3 with invalid data returns error changeset", %{session: session} do
      store = default_store()

      assert {:error, %Ecto.Changeset{}} = Shops.update_store(session, store, @invalid_attrs)
      assert store.id == Shops.get_store!(session.account).id
    end

    test "change_store/2 returns a store changeset", %{session: session} do
      store = default_store()

      assert %Ecto.Changeset{} = Shops.change_store(session.account, store)
    end

    test "change_store/3 returns a store changeset", %{session: session} do
      store = default_store()

      assert %Ecto.Changeset{} = Shops.change_store(session.account, store, %{name: "Other name"})
    end
  end
end
