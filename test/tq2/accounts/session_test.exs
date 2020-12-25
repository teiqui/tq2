defmodule Tq2.Accounts.SessionTest do
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
        password: "123456",
        role: "owner"
      })

    {:ok, user} = Accounts.create_user(session, user_attrs)

    {%{user | password: nil}, account}
  end

  describe "session" do
    test "get_session/2 returns the session with given account and user id" do
      {user, account} = user_fixture()
      %Session{} = session = Session.get_session(account.id, user.id)

      assert user.id == session.user.id
      assert account.id == session.account.id
    end

    test "get_session/2 returns nil when any argument is nil" do
      refute Session.get_session(nil, 1)
      refute Session.get_session(1, nil)
      refute Session.get_session(nil, nil)
    end
  end
end
