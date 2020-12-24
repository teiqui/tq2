defmodule Tq2.Accounts.PasswordTest do
  use Tq2.DataCase

  alias Tq2.Repo
  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, Password, Session, User}

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

  describe "get user by token" do
    test "get_user_by_token/1 returns the user with given token" do
      user = user_with_password_reset_token()

      assert Password.get_user_by_token(user.password_reset_token).id == user.id
    end

    test "get_user_by_token/1 returns no result when token mismatch" do
      user_with_password_reset_token()

      assert Password.get_user_by_token("wrong-token") == nil
    end

    test "get_user_by_token/1 returns no result when token is expired" do
      user =
        user_fixture()
        |> expired_password_reset_changeset()
        |> Repo.update!()

      assert Password.get_user_by_token(user.password_reset_token) == nil
    end
  end

  describe "reset" do
    use Bamboo.Test

    alias Tq2.Notifications.Email

    test "reset" do
      user = user_fixture()

      refute user.password_reset_token

      Password.reset(user)

      user = Repo.get!(User, user.id)

      assert user.password_reset_token

      assert_delivered_email(Email.password_reset(user))
    end
  end

  defp user_with_password_reset_token do
    user_fixture()
    |> User.password_reset_token_changeset()
    |> Repo.update!()
  end

  defp expired_password_reset_changeset(%User{} = user) do
    sent_at =
      NaiveDateTime.utc_now()
      |> NaiveDateTime.add(-6 * 60 * 60 - 1)

    attrs = %{
      password_reset_token: "WuxowusAqmrkmBYpTFcTxDUsaoqipm17u0mdrCcMCRJVJtF",
      password_reset_sent_at: sent_at
    }

    cast(user, attrs, [:password_reset_token, :password_reset_sent_at])
  end
end
