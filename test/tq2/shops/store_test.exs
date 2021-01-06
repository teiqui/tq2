defmodule Tq2.Shops.StoreTest do
  use Tq2.DataCase, async: true

  describe "store" do
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
  end

  defp default_account do
    Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")
  end
end
