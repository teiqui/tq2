defmodule Tq2.Accounts.LicenseTest do
  use Tq2.DataCase, async: true

  describe "license" do
    alias Tq2.Accounts.License

    @valid_attrs %{
      status: "trial"
    }
    @invalid_attrs %{
      status: "unknown"
    }

    test "changeset with valid attributes" do
      changeset = License.changeset(%License{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = License.changeset(%License{}, @invalid_attrs)

      refute changeset.valid?

      assert "is invalid" in errors_on(changeset).status
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:status, String.duplicate("a", 256))

      changeset = License.changeset(%License{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).status
    end

    test "changeset check inclusions" do
      attrs =
        @valid_attrs
        |> Map.put(:status, "xx")

      changeset = License.changeset(%License{}, attrs)

      assert "is invalid" in errors_on(changeset).status
    end

    test "price_for/1 returns monthly price for country" do
      assert %Money{amount: 49900, currency: :ARS} == License.price_for("ar")
    end

    test "price_for/2 returns price for country" do
      assert %Money{amount: 49900, currency: :ARS} == License.price_for("ar", :monthly)
      assert %Money{amount: 499_000, currency: :ARS} == License.price_for("ar", :yearly)
    end

    test "price_for/2 returns default price for not local country" do
      assert %Money{amount: 399, currency: :USD} == License.price_for("uy", :monthly)
      assert %Money{amount: 3990, currency: :USD} == License.price_for("uy", :yearly)
    end
  end
end
