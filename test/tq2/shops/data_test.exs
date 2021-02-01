defmodule Tq2.Shops.DataTest do
  use Tq2.DataCase, async: true

  import Tq2.Fixtures, only: [default_account: 1]

  describe "data" do
    alias Tq2.Shops.Data

    @valid_attrs %{
      phone: "555-5555",
      email: "some@email.com",
      whatsapp: "+549555-5555",
      facebook: "some facebook",
      instagram: "some instagram"
    }
    @invalid_attrs %{
      phone: "123",
      email: "wrong",
      whatsapp: "123",
      facebook: nil,
      instagram: nil
    }

    setup [:default_account]

    test "changeset with valid attributes", %{account: account} do
      changeset = Data.changeset(%Data{}, @valid_attrs, account)

      assert changeset.valid?
    end

    test "changeset with invalid attributes", %{account: account} do
      changeset = Data.changeset(%Data{}, @invalid_attrs, account)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:phone, String.duplicate("5", 256))
        |> Map.put(:email, String.duplicate("a", 256))
        |> Map.put(:whatsapp, String.duplicate("a", 256))
        |> Map.put(:facebook, String.duplicate("a", 256))
        |> Map.put(:instagram, String.duplicate("a", 256))

      changeset = Data.changeset(%Data{}, attrs, account)

      assert "should be at most 255 character(s)" in errors_on(changeset).phone
      assert "should be at most 255 character(s)" in errors_on(changeset).email
      assert "should be at most 255 character(s)" in errors_on(changeset).whatsapp
      assert "should be at most 255 character(s)" in errors_on(changeset).facebook
      assert "should be at most 255 character(s)" in errors_on(changeset).instagram
    end

    test "changeset check format", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:email, "x")

      changeset = Data.changeset(%Data{}, attrs, account)

      assert "has invalid format" in errors_on(changeset).email
    end

    test "changeset does not accept invalid phones", %{account: account} do
      attrs =
        @valid_attrs
        |> Map.put(:phone, "+a")
        |> Map.put(:whatsapp, "+a")

      changeset = Data.changeset(%Data{}, attrs, account)

      assert "is invalid" in errors_on(changeset).phone
      assert "is invalid" in errors_on(changeset).whatsapp
    end
  end
end
