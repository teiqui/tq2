defmodule Tq2.Accounts.UserRepoTest do
  use Tq2.DataCase

  describe "user" do
    alias Tq2.Accounts
    alias Tq2.Accounts.{Account, Session, User}

    @valid_attrs %{
      email: "some@email.com",
      lastname: "some lastname",
      name: "some name",
      password: "123456"
    }

    def user_fixture(attrs \\ %{}) do
      account = Tq2.Repo.get_by!(Account, name: "test_account")
      session = %Session{account: account}

      user_attrs =
        Enum.into(attrs, %{
          email: "some@email.com",
          lastname: "some lastname",
          name: "some name",
          password: "123456"
        })

      {:ok, user} = Accounts.create_user(session, user_attrs)

      %{user | password: nil}
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
