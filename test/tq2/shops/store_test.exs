defmodule Tq2.Shops.StoreTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures, only: [app_wire_transfer_fixture: 0]

  describe "store" do
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
        require_address: true,
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
        whatsapp: "+549555-5555",
        facebook: "some facebook",
        instagram: "some instagram"
      },
      location: %{
        latitude: "12",
        longitude: "123"
      },
      account_id: "1"
    }
    @invalid_attrs %{
      name: nil,
      description: nil,
      slug: nil,
      published: nil,
      logo: nil,
      configuration: %{
        require_email: nil,
        require_phone: nil,
        require_address: nil,
        pickup: nil,
        pickup_time_limit: nil,
        address: nil,
        delivery: nil,
        delivery_area: nil,
        delivery_time_limit: nil,
        pay_on_delivery: nil
      },
      data: %{
        phone: nil,
        email: nil,
        whatsapp: nil,
        facebook: nil,
        instagram: nil
      },
      location: %{
        latitude: nil,
        longitude: nil
      },
      account_id: nil
    }

    test "changeset with valid attributes" do
      changeset = default_account() |> Store.changeset(%Store{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = default_account() |> Store.changeset(%Store{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:name, String.duplicate("a", 256))
        |> Map.put(:slug, String.duplicate("a", 256))

      changeset = default_account() |> Store.changeset(%Store{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).name
      assert "should be at most 255 character(s)" in errors_on(changeset).slug
    end

    test "changeset check format" do
      attrs =
        @valid_attrs
        |> Map.put(:slug, "x x")

      changeset = default_account() |> Store.changeset(%Store{}, attrs)

      assert "has invalid format" in errors_on(changeset).slug
    end

    test "slugified" do
      assert "s_l_ugified" == Store.slugified("S L Ugi%%^fied")
    end

    test "available_payment_methods/1 returns only cash" do
      store = %Store{account: default_account()} |> Map.merge(@valid_attrs)

      assert ["cash"] = Store.available_payment_methods(store)
    end

    test "available_payment_methods/1 returns empty list" do
      store = %Store{
        account: default_account(),
        account_id: 1,
        configuration: %{pickup: false, pay_on_delivery: false}
      }

      assert [] = Store.available_payment_methods(store)
    end

    test "available_payment_methods/1 returns app names" do
      app_wire_transfer_fixture()

      store = %Store{account: default_account()} |> Map.merge(@valid_attrs)

      assert ["cash", "wire_transfer"] = Store.available_payment_methods(store)
    end
  end

  defp default_account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end
end
