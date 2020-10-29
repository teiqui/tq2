defmodule Tq2.Accounts.AccountTest do
  use Tq2.DataCase, async: true

  describe "account" do
    alias Tq2.Accounts.Account

    @valid_attrs %{
      name: "some name",
      country: "ar",
      status: "active",
      time_zone: "America/Argentina/Mendoza"
    }
    @invalid_attrs %{name: nil, country: "wrong", status: "wrong", time_zone: "wrong"}

    test "changeset with valid attributes" do
      changeset = Account.changeset(%Account{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Account.changeset(%Account{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:name, String.duplicate("a", 256))
        |> Map.put(:status, String.duplicate("a", 256))

      changeset = Account.changeset(%Account{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).name
      assert "should be at most 255 character(s)" in errors_on(changeset).status
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:country, "xx")
        |> Map.put(:status, "xx")
        |> Map.put(:time_zone, "xx")

      changeset = Account.changeset(%Account{}, attrs)

      assert "is invalid" in errors_on(changeset).country
      assert "is invalid" in errors_on(changeset).status
      assert "is invalid" in errors_on(changeset).time_zone
    end
  end
end
