defmodule Tq2.Accounts.UserRepoTest do
  use Tq2.DataCase

  describe "user" do
    alias Tq2.Accounts
    alias Tq2.Accounts.User

    @valid_attrs %{
      email: "some@email.com",
      lastname: "some lastname",
      name: "some name",
      password: "123456"
    }

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_user()

      user
    end

    test "converts unique constraint on email to error" do
      user = user_fixture(@valid_attrs)
      attrs = Map.put(@valid_attrs, :email, user.email)
      changeset = User.create_changeset(%User{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:email]]
      }

      assert expected == changeset.errors[:email]
    end
  end
end
