defmodule Tq2.AccountsTest do
  use Tq2.DataCase

  alias Tq2.Accounts

  defp create_session(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")

    {:ok, session: %Tq2.Accounts.Session{account: account}}
  end

  describe "accounts" do
    alias Tq2.Accounts.Account

    @valid_attrs %{
      country: "ar",
      name: "some name",
      status: "active",
      time_zone: "America/Argentina/Mendoza"
    }
    @update_attrs %{
      country: "mx",
      name: "some updated name",
      status: "green",
      time_zone: "America/Argentina/Cordoba"
    }
    @invalid_attrs %{country: nil, name: nil, status: nil, time_zone: nil}

    def account_fixture(attrs \\ %{}) do
      {:ok, account} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Accounts.create_account()

      account
    end

    test "list_accounts/1 returns all accounts" do
      account = account_fixture()
      default_account = Tq2.Repo.get_by!(Account, name: "test_account")

      assert Enum.map(Accounts.list_accounts(%{}).entries, & &1.id) == [
               default_account.id,
               account.id
             ]
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert Accounts.get_account!(account.id) == account
    end

    test "create_account/1 with valid data creates a account" do
      assert {:ok, %Account{} = account} = Accounts.create_account(@valid_attrs)
      assert account.country == "ar"
      assert account.name == "some name"
      assert account.status == "active"
      assert account.time_zone == "America/Argentina/Mendoza"
    end

    test "create_account/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_account(@invalid_attrs)
    end

    test "update_account/2 with valid data updates the account" do
      account = account_fixture()
      assert {:ok, %Account{} = account} = Accounts.update_account(account, @update_attrs)
      assert account.country == "mx"
      assert account.name == "some updated name"
      assert account.status == "green"
      assert account.time_zone == "America/Argentina/Cordoba"
    end

    test "update_account/2 with invalid data returns error changeset" do
      account = account_fixture()
      assert {:error, %Ecto.Changeset{}} = Accounts.update_account(account, @invalid_attrs)
      assert account == Accounts.get_account!(account.id)
    end

    test "delete_account/1 deletes the account" do
      account = account_fixture()
      assert {:ok, %Account{}} = Accounts.delete_account(account)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_account!(account.id) end
    end

    test "change_account/1 returns a account changeset" do
      account = account_fixture()
      assert %Ecto.Changeset{} = Accounts.change_account(account)
    end
  end

  describe "users" do
    setup [:create_session]

    alias Tq2.Accounts.User

    @valid_attrs %{
      email: "some@email.com",
      lastname: "some lastname",
      name: "some name",
      password: "123456"
    }
    @update_attrs %{
      email: "new@email.com",
      lastname: "some updated lastname",
      name: "some updated name"
    }
    @invalid_attrs %{email: "wrong@email", lastname: nil, name: nil, password: "123"}

    defp user_fixture(session, attrs \\ %{}) do
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

    test "list_users/2 returns all users", %{session: session} do
      user = user_fixture(session)
      assert Enum.map(Accounts.list_users(session.account, %{}).entries, & &1.id) == [user.id]
    end

    test "list_users/2 returns no users when new account", %{session: session} do
      account = account_fixture(%{name: "accounts_test"})

      user_fixture(session)

      assert Accounts.list_users(account, %{}).entries == []
    end

    test "get_user!/2 returns the user with given id", %{session: session} do
      user = user_fixture(session)
      assert Accounts.get_user!(session.account, user.id).id == user.id
    end

    test "get_user!/2 returns no result when user account and id mismatch", %{session: session} do
      account = account_fixture(%{name: "accounts_user_test"})
      user = user_fixture(session)

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(account, user.id)
      end
    end

    test "get_user/1 returns user when email option is correct", %{session: session} do
      user = user_fixture(session)

      assert Accounts.get_user(email: user.email).id == user.id
    end

    test "get_user/1 returns nil when email option is incorrect" do
      refute Accounts.get_user(email: "no@user.com")
    end

    test "get_user/1 returns user when token option is correct", %{session: session} do
      user =
        session
        |> user_fixture()
        |> User.password_reset_token_changeset()
        |> Repo.update!()

      assert Accounts.get_user(token: user.password_reset_token).id == user.id
    end

    test "get_user/1 returns nil when token option is incorrect" do
      refute Accounts.get_user(token: "wrong-token")
    end

    test "create_user/2 with valid data creates a user", %{session: session} do
      assert {:ok, %User{} = user} = Accounts.create_user(session, @valid_attrs)
      assert user.email == "some@email.com"
      assert user.lastname == "some lastname"
      assert user.name == "some name"
    end

    test "create_user/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(session, @invalid_attrs)
    end

    test "update_user/3 with valid data updates the user", %{session: session} do
      user = user_fixture(session)
      assert {:ok, %User{} = user} = Accounts.update_user(session, user, @update_attrs)
      assert user.email == "new@email.com"
      assert user.lastname == "some updated lastname"
      assert user.name == "some updated name"
    end

    test "update_user/3 with invalid data returns error changeset", %{session: session} do
      user = user_fixture(session)
      assert {:error, %Ecto.Changeset{}} = Accounts.update_user(session, user, @invalid_attrs)
      assert user.id == Accounts.get_user!(session.account, user.id).id
    end

    test "update_user_password/2 with valid data updates the user", %{session: session} do
      attrs = %{password: "newpass", password_confirmation: "newpass"}
      user = user_fixture(session)

      assert {:ok, user} = Accounts.update_user_password(user, attrs)
      assert Argon2.verify_pass(attrs.password, user.password_hash)
    end

    test "update_user_password/2 with invalid data returns error changeset", %{session: session} do
      attrs = %{password: "newpass", password_confirmation: "wrong"}
      user = user_fixture(session)

      assert {:error, %Ecto.Changeset{}} = Accounts.update_user_password(user, attrs)
      assert user.id == Accounts.get_user!(session.account, user.id).id
    end

    test "delete_user/2 deletes the user", %{session: session} do
      user = user_fixture(session)
      assert {:ok, %User{}} = Accounts.delete_user(session, user)
      assert_raise Ecto.NoResultsError, fn -> Accounts.get_user!(session.account, user.id) end
    end

    test "change_user/1 returns a user changeset", %{session: session} do
      user = user_fixture(session)
      assert %Ecto.Changeset{} = Accounts.change_user(user)
    end

    test "change_user_password/1 returns a user changeset", %{session: session} do
      user = user_fixture(session)

      assert %Ecto.Changeset{} = Accounts.change_user_password(user)
    end
  end

  describe "session" do
    setup [:create_session]

    alias Tq2.Accounts.Session

    test "get_current_session/2 returns the session with given account and user id", %{
      session: session
    } do
      user = user_fixture(session)
      %Session{} = current_session = Accounts.get_current_session(session.account.id, user.id)

      assert user.id == current_session.user.id
      assert session.account.id == current_session.account.id
    end
  end

  describe "auth" do
    setup [:create_session]

    test "authenticate_by_email_and_password/2 returns :ok with valid credentials", %{
      session: session
    } do
      user = user_fixture(session)
      email = @valid_attrs.email
      password = @valid_attrs.password

      {:ok, auth_user} = Accounts.authenticate_by_email_and_password(email, password)

      assert auth_user.id == user.id
    end

    test "authenticate_by_email_and_password/2 returns :error with invalid credentials", %{
      session: session
    } do
      user = user_fixture(session)

      assert {:error, :unauthorized} ==
               Accounts.authenticate_by_email_and_password(user.email, "wrong")
    end

    test "authenticate_by_email_and_password/2 returns :error with invalid email", %{
      session: session
    } do
      user = user_fixture(session)
      password = @valid_attrs.password

      assert {:error, :unauthorized} ==
               Accounts.authenticate_by_email_and_password("#{user.email}x", password)
    end
  end

  describe "password" do
    setup [:create_session]

    alias Tq2.Notifications.Email
    use Bamboo.Test

    test "reset", %{session: session} do
      user = user_fixture(session)
      {:ok, user} = Accounts.password_reset(user)

      assert_delivered_email(Email.password_reset(user))
    end
  end
end
