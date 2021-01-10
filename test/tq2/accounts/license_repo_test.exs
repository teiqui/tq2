defmodule Tq2.Accounts.LicenseRepoTest do
  use Tq2.DataCase

  describe "License" do
    alias Tq2.Accounts.License

    @valid_attrs %{
      status: "trial"
    }

    def license_fixture(attrs \\ %{}) do
      {:ok, license} =
        License
        |> Repo.one()
        |> License.changeset(attrs)
        |> Repo.update()

      license
    end

    test "converts unique constraint on customer_id error" do
      license = license_fixture(%{customer_id: "cus_123"})
      attrs = @valid_attrs |> Map.put(:customer_id, license.customer_id)
      changeset = License.changeset(%License{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:customer_id]]
      }

      assert expected == changeset.errors[:customer_id]
    end

    test "converts unique constraint on external_id error" do
      license = license_fixture(%{subscription_id: "sub_123"})
      attrs = @valid_attrs |> Map.put(:subscription_id, license.subscription_id)
      changeset = License.changeset(%License{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:subscription_id]]
      }

      assert expected == changeset.errors[:subscription_id]
    end
  end
end
