defmodule Tq2.Accounts.LicenseRepoTest do
  use Tq2.DataCase

  describe "License" do
    alias Tq2.Accounts.License

    @valid_attrs %{
      status: "trial",
      reference: ""
    }

    def license_fixture(attrs \\ %{}) do
      {:ok, license} =
        License
        |> Repo.one()
        |> License.changeset(attrs)
        |> Repo.update()

      license
    end

    test "converts unique constraint on reference to error" do
      license = license_fixture(%{reference: Ecto.UUID.generate()})
      attrs = Map.put(@valid_attrs, :reference, license.reference)
      changeset = License.changeset(%License{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:reference]]
      }

      assert expected == changeset.errors[:reference]
    end
  end
end
