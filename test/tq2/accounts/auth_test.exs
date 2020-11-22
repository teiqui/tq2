defmodule Tq2.Accounts.AuthTest do
  use Tq2.DataCase

  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, Session}

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

  describe "auth" do
    alias Tq2.Accounts.Auth

    test "authenticate_by_email_and_password/2 returns :ok with valid credentials" do
      user = user_fixture()
      email = String.upcase(" #{user.email} ")
      password = "123456"
      {:ok, auth_user} = Auth.authenticate_by_email_and_password(email, password)

      assert auth_user.id == user.id
    end

    test "authenticate_by_email_and_password/2 returns :error with invalid credentials" do
      user = user_fixture()
      email = user.email
      password = "wrong"

      assert {:error, :unauthorized} == Auth.authenticate_by_email_and_password(email, password)
    end

    test "authenticate_by_email_and_password/2 returns :error with invalid email" do
      email = "invalid@email.com"
      password = "123456"

      assert {:error, :unauthorized} == Auth.authenticate_by_email_and_password(email, password)
    end
  end
end
