defmodule Tq2.AccountsTest do
  use Tq2.DataCase

  import Tq2.Fixtures, only: [create_order: 1, create_session: 1, default_account: 0]

  alias Tq2.Accounts
  alias Tq2.Accounts.Account

  describe "accounts" do
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

    test "stream_accounts/0 returns stream to all accounts" do
      account = account_fixture()
      default_account = Tq2.Repo.get_by!(Account, name: "test_account")

      Tq2.Repo.transaction(fn ->
        assert Enum.sort(Enum.map(Enum.to_list(Accounts.stream_accounts()), & &1.id)) == [
                 default_account.id,
                 account.id
               ]
      end)
    end

    test "list_accounts/1 returns all accounts" do
      account = account_fixture()
      default_account = Tq2.Repo.get_by!(Account, name: "test_account")

      assert Enum.sort(Enum.map(Accounts.list_accounts(%{}).entries, & &1.id)) == [
               default_account.id,
               account.id
             ]
    end

    test "list_accounts/1 returns accounts filtered by name" do
      account = account_fixture()
      default_account = Tq2.Repo.get_by!(Account, name: "test_account")

      assert Enum.map(Accounts.list_accounts(%{"name" => "test_account"}).entries, & &1.id) == [
               default_account.id
             ]

      assert Enum.map(Accounts.list_accounts(%{"name" => "some"}).entries, & &1.id) == [
               account.id
             ]
    end

    test "list_accounts/1 returns accounts when they match filters" do
      account = account_fixture()
      default_account = Tq2.Repo.get_by!(Account, name: "test_account")
      expected = [default_account.id, account.id]
      params = %{"inserted_from" => Timex.now() |> Timex.beginning_of_day()}

      assert Enum.sort(Enum.map(Accounts.list_accounts(params).entries, & &1.id)) == expected

      params = %{"inserted_to" => Timex.now() |> Timex.end_of_day()}

      assert Enum.sort(Enum.map(Accounts.list_accounts(params).entries, & &1.id)) == expected

      params = %{
        "inserted_from" => Timex.now() |> Timex.beginning_of_day(),
        "inserted_to" => Timex.now() |> Timex.end_of_day()
      }

      assert Enum.sort(Enum.map(Accounts.list_accounts(params).entries, & &1.id)) == expected

      params = %{
        "inserted_from" => Timex.now() |> Timex.shift(days: 1) |> Timex.beginning_of_day()
      }

      assert Accounts.list_accounts(params).entries == []

      params = %{"inserted_to" => Timex.now() |> Timex.shift(days: -1) |> Timex.end_of_day()}

      assert Accounts.list_accounts(params).entries == []

      params = %{
        "inserted_from" => Timex.now() |> Timex.shift(days: -1) |> Timex.beginning_of_day(),
        "inserted_to" => Timex.now() |> Timex.shift(days: -1) |> Timex.end_of_day()
      }

      assert Accounts.list_accounts(params).entries == []
    end

    test "get_account!/1 returns the account with given id" do
      account = account_fixture()
      assert Accounts.get_account!(account.id).id == account.id
    end

    test "get_account_stats/1 returns account stats counts" do
      account = default_account()

      assert Accounts.get_account_stats(account) == [orders_count: 0, carts_count: 0]

      create_order(nil)

      assert Accounts.get_account_stats(account) == [orders_count: 1, carts_count: 1]
    end

    test "create_account/1 with valid data creates a account and license" do
      assert {:ok, %Account{} = account} = Accounts.create_account(@valid_attrs)
      assert account.country == "ar"
      assert account.name == "some name"
      assert account.status == "active"
      assert account.time_zone == "America/Argentina/Mendoza"
      assert account.license.status == "trial"
      assert account.license.paid_until == Timex.shift(Timex.today(), days: 14)
    end

    test "create_account/1 with valid data creates a account with timmed attrs" do
      attrs =
        @valid_attrs
        |> Map.put(:name, " some name \n   ")
        |> Map.put(:time_zone, " America/Argentina/Mendoza\n  ")

      assert {:ok, %Account{} = account} = Accounts.create_account(attrs)
      assert account.name == "some name"
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
      assert account.id == Accounts.get_account!(account.id).id
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
      name: "some name",
      lastname: "some lastname",
      email: "some@email.com",
      password: "123456",
      role: "owner"
    }
    @update_attrs %{
      name: "some updated name",
      lastname: "some updated lastname",
      email: "new@email.com",
      role: "owner"
    }
    @invalid_attrs %{
      name: nil,
      lastname: nil,
      email: "wrong@email",
      password: "123",
      role: nil
    }

    defp user_fixture(session, attrs \\ %{}) do
      user_attrs =
        Enum.into(attrs, %{
          email: "some@email.com",
          lastname: "some lastname",
          name: "some name",
          password: "123456",
          role: "owner"
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

    test "get_owner/1 returns the owner user of the account", %{session: session} do
      user = user_fixture(session)
      user_fixture(session, %{email: "other_user@sample.com"})

      assert Accounts.get_owner(session.account).id == user.id
    end

    test "get_owner/1 returns nil when account has no users", %{session: session} do
      refute Accounts.get_owner(session.account)
    end

    test "create_user/2 with valid data creates a user", %{session: session} do
      assert {:ok, %User{} = user} = Accounts.create_user(session, @valid_attrs)
      assert user.name == @valid_attrs.name
      assert user.lastname == @valid_attrs.lastname
      assert user.email == @valid_attrs.email
    end

    test "create_user/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_user(session, @invalid_attrs)
    end

    test "update_user/3 with valid data updates the user", %{session: session} do
      user = user_fixture(session)
      assert {:ok, %User{} = user} = Accounts.update_user(session, user, @update_attrs)
      assert user.name == @update_attrs.name
      assert user.lastname == @update_attrs.lastname
      assert user.email == @update_attrs.email
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

    test "get_account_owner!/1 returns the owner user", %{session: session} do
      user = user_fixture(session)
      _other_user = user_fixture(session, %{email: "other@email.com"})

      owner = session.account |> Accounts.get_account_owner!()

      # same user
      assert user.id == owner.id
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

    use Bamboo.Test

    alias Tq2.Notifications.Email

    test "reset", %{session: session} do
      user = user_fixture(session)
      {:ok, user} = Accounts.password_reset(user)

      assert_delivered_email(Email.password_reset(user))
    end
  end

  describe "licenses" do
    setup [:create_session]

    alias Tq2.Accounts.License

    @update_attrs %{
      status: "active",
      customer_id: "cus_123asd",
      subscription_id: "sub_123asd"
    }
    @invalid_attrs %{status: "unknown"}

    defp fixture(session, :license, attrs \\ %{}) do
      {:ok, license} =
        session.account.license
        |> License.changeset(attrs)
        |> Repo.update()

      %{license | account: session.account}
    end

    test "get_license!/1 returns the license with given account", %{session: session} do
      license = fixture(session, :license)

      assert Accounts.get_license!(session.account) == license
    end

    test "get_license!/1 returns the license with customer_id value", %{session: session} do
      license = fixture(session, :license, %{customer_id: "cus_123"})

      assert Accounts.get_license!(customer_id: "cus_123").id == license.id
    end

    test "get_license!/1 returns the license with subscription_id value", %{session: session} do
      license = fixture(session, :license, %{subscription_id: "sub_123"})

      assert Accounts.get_license!(subscription_id: "sub_123").id == license.id
    end

    test "update_license/3 with valid data updates the license", %{session: session} do
      license = fixture(session, :license)

      assert {:ok, license} = Accounts.update_license(session, license, @update_attrs)
      assert %License{} = license
      assert license.status == @update_attrs.status
      assert license.customer_id == @update_attrs.customer_id
      assert license.subscription_id == @update_attrs.subscription_id
    end

    test "update_license/2 with valid data updates the license", %{session: session} do
      license = fixture(session, :license)

      assert {:ok, license} = Accounts.update_license(license, @update_attrs)
      assert %License{} = license
      assert license.status == @update_attrs.status
      assert license.customer_id == @update_attrs.customer_id
      assert license.subscription_id == @update_attrs.subscription_id
    end

    test "update_license/3 with invalid data returns error changeset", %{session: session} do
      license = fixture(session, :license)

      assert {:error, %Ecto.Changeset{}} =
               Accounts.update_license(session, license, @invalid_attrs)

      assert license == Accounts.get_license!(session.account)
    end

    test "delete_license/2 deletes the license", %{session: session} do
      assert {:ok, %License{}} = Accounts.delete_license(session)

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_license!(session.account)
      end
    end
  end

  describe "registrations" do
    alias Tq2.Accounts.Registration

    @valid_attrs %{
      "name" => "some name",
      "type" => "grocery",
      "email" => "some@email.com",
      "phone" => "+54 555-7777",
      "password" => "123456",
      "country" => "ar",
      "time_zone" => "America/Argentina/Buenos_Aires",
      "campaign" => "Sofi"
    }
    @invalid_attrs %{
      name: nil,
      type: nil,
      email: nil,
      phone: nil,
      password: nil
    }

    defp registration_fixture(attrs \\ %{}) do
      registration_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, %{registration: registration}} = Accounts.create_registration(registration_attrs)

      registration
    end

    test "get_registration!/1 returns the registration with given id" do
      registration = registration_fixture()

      assert Accounts.get_registration!(registration.uuid).id == registration.id
    end

    test "get_registration!/1 returns the registration with given id only for 2 minutes" do
      registration = registration_fixture()

      one_minute_ago = Timex.now() |> Timex.shift(minutes: -1) |> DateTime.truncate(:second)

      registration |> Ecto.Changeset.change(%{accessed_at: one_minute_ago}) |> Tq2.Repo.update!()

      assert Accounts.get_registration!(registration.uuid).id == registration.id

      three_minutes_ago = Timex.now() |> Timex.shift(minutes: -3) |> DateTime.truncate(:second)

      registration
      |> Ecto.Changeset.change(%{accessed_at: three_minutes_ago})
      |> Tq2.Repo.update!()

      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_registration!(registration.uuid)
      end
    end

    test "create_registration/1 with valid data creates account and user" do
      assert {:ok, %{account: account, store: store, user: user, registration: registration}} =
               Accounts.create_registration(@valid_attrs)

      trial_until = Timex.today() |> Timex.shift(days: 14)

      assert %Registration{} = registration
      assert registration.name == @valid_attrs["name"]
      assert registration.type == @valid_attrs["type"]
      assert registration.email == @valid_attrs["email"]
      assert registration.phone == @valid_attrs["phone"]
      assert registration.account_id == account.id
      assert account.name == @valid_attrs["name"]
      assert store.name == @valid_attrs["name"]
      assert store.data.phone == @valid_attrs["phone"]
      assert store.slug == Tq2.Shops.Store.slugified(@valid_attrs["name"])
      assert user.email == @valid_attrs["email"]
      assert account.license.paid_until == trial_until
    end

    test "create_registration/1 with repeated name creates account, user and store" do
      {:ok, session: session} = create_session(%{})

      {:ok, _} =
        Tq2.Shops.create_store(
          session,
          %{
            name: @valid_attrs["name"],
            description: @valid_attrs["name"],
            published: true,
            slug: Tq2.Shops.Store.slugified(@valid_attrs["name"]),
            data: %{},
            location: %{},
            configuration: %{
              pickup: true,
              pickup_time_limit: "-"
            }
          }
        )

      assert {:ok, %{account: account, user: user, registration: registration, store: store}} =
               Accounts.create_registration(@valid_attrs)

      assert %Registration{} = registration
      assert registration.name == @valid_attrs["name"]
      assert registration.type == @valid_attrs["type"]
      assert registration.email == @valid_attrs["email"]
      assert registration.phone == @valid_attrs["phone"]
      assert registration.account_id == account.id
      assert account.name == @valid_attrs["name"]
      assert user.email == @valid_attrs["email"]
      assert store.name == @valid_attrs["name"]
      assert store.data.phone == @valid_attrs["phone"]
      refute store.slug == Tq2.Shops.Store.slugified(@valid_attrs["name"])
    end

    test "create_registration/1 with extended campaign" do
      {:ok, %{account: %{license: license}}} =
        %{@valid_attrs | "campaign" => "extended_trial"}
        |> Accounts.create_registration()

      trial_until = Timex.today() |> Timex.shift(days: 30)

      assert license.paid_until == trial_until
    end

    test "create_registration/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Accounts.create_registration(@invalid_attrs)
    end

    test "access_registration/1 mark the registration as accessed" do
      registration = registration_fixture()

      assert registration.accessed_at == nil

      assert {:ok, registration} = Accounts.access_registration(registration)

      assert %Registration{} = registration
      refute registration.accessed_at == nil
    end

    test "change_registration/1 returns a registration changeset" do
      registration = registration_fixture()

      assert %Ecto.Changeset{} = Accounts.change_registration(registration)
    end
  end
end
