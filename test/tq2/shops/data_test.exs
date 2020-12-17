defmodule Tq2.Shops.DataTest do
  use Tq2.DataCase, async: true

  describe "data" do
    alias Tq2.Shops.Data

    @valid_attrs %{
      phone: "555-5555",
      email: "some@email.com",
      whatsapp: "some whatsapp",
      facebook: "some facebook",
      instagram: "some instagram"
    }
    @invalid_attrs %{
      phone: nil,
      email: "wrong",
      whatsapp: nil,
      facebook: nil,
      instagram: nil
    }

    test "changeset with valid attributes" do
      changeset = Data.changeset(%Data{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Data.changeset(%Data{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:phone, String.duplicate("5", 256))
        |> Map.put(:email, String.duplicate("a", 256))
        |> Map.put(:whatsapp, String.duplicate("a", 256))
        |> Map.put(:facebook, String.duplicate("a", 256))
        |> Map.put(:instagram, String.duplicate("a", 256))

      changeset = Data.changeset(%Data{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).phone
      assert "should be at most 255 character(s)" in errors_on(changeset).email
      assert "should be at most 255 character(s)" in errors_on(changeset).whatsapp
      assert "should be at most 255 character(s)" in errors_on(changeset).facebook
      assert "should be at most 255 character(s)" in errors_on(changeset).instagram
    end

    test "changeset check format" do
      attrs =
        @valid_attrs
        |> Map.put(:email, "x")

      changeset = Data.changeset(%Data{}, attrs)

      assert "has invalid format" in errors_on(changeset).email
    end
  end
end
