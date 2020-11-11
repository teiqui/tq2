defmodule Tq2.Accounts.LicenseTest do
  use Tq2.DataCase, async: true

  describe "license" do
    alias Tq2.Accounts.License

    @valid_attrs %{
      status: "trial",
      reference: "123"
    }
    @invalid_attrs %{
      status: "unknown",
      reference: ""
    }

    test "changeset with valid attributes" do
      changeset = License.changeset(%License{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = License.changeset(%License{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:reference, String.duplicate("a", 256))
        |> Map.put(:status, String.duplicate("a", 256))

      changeset = License.changeset(%License{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).reference
      assert "should be at most 255 character(s)" in errors_on(changeset).status
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:status, "xx")

      changeset = License.changeset(%License{}, attrs)

      assert "is invalid" in errors_on(changeset).status
    end
  end
end