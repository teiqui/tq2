defmodule Tq2.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  import Tq2.Utils.CountryCurrency, only: [time_zone_or_country_default: 2]
  import Tq2Web.Gettext

  alias Ecto.Multi
  alias Tq2.{Repo, Trail}
  alias Tq2.Accounts.{Account, License}

  @doc """
  Returns the list of accounts.

  ## Examples

      iex> list_accounts(%{})
      [%Account{}, ...]

  """
  def list_accounts(params) do
    Repo.paginate(Account, params)
  end

  @doc """
  Gets a single account.

  Raises `Ecto.NoResultsError` if the Account does not exist.

  ## Examples

      iex> get_account!(123)
      %Account{}

      iex> get_account!(456)
      ** (Ecto.NoResultsError)

  """
  def get_account!(id), do: Repo.get!(Account, id)

  @doc """
  Creates a account.

  ## Examples

      iex> create_account(%{field: value})
      {:ok, %Account{}}

      iex> create_account(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_account(attrs \\ %{}) do
    attrs = License.put_create_account_attrs(attrs)

    %Account{}
    |> Account.create_changeset(attrs)
    |> Trail.insert()
  end

  @doc """
  Updates a account.

  ## Examples

      iex> update_account(account, %{field: new_value})
      {:ok, %Account{}}

      iex> update_account(account, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_account(%Account{} = account, attrs) do
    account
    |> Account.changeset(attrs)
    |> Trail.update()
  end

  @doc """
  Deletes a account.

  ## Examples

      iex> delete_account(account)
      {:ok, %Account{}}

      iex> delete_account(account)
      {:error, %Ecto.Changeset{}}

  """
  def delete_account(%Account{} = account) do
    Trail.delete(account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking account changes.

  ## Examples

      iex> change_account(account)
      %Ecto.Changeset{data: %Account{}}

  """
  def change_account(%Account{} = account, attrs \\ %{}) do
    Account.changeset(account, attrs)
  end

  alias Tq2.Accounts.{Membership, Session, User}

  @doc """
  Returns the list of users.

  ## Examples

      iex> list_users(%Account{}, %{})
      [%User{}, ...]

  """
  def list_users(%Account{} = account, params) do
    query =
      from(
        u in User,
        join: m in assoc(u, :memberships),
        where: m.account_id == ^account.id,
        order_by: u.email
      )

    Repo.paginate(query, params)
  end

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(%Account{id: 1}, 123)
      %User{}

      iex> get_user!(%Account{id: 2}, 456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(%Account{} = account, id) do
    query =
      from(
        u in User,
        join: m in assoc(u, :memberships),
        where: m.account_id == ^account.id
      )

    Repo.get!(query, id)
  end

  @doc """
  Gets the account owner.

  Returns nil if the owner does not exist.

  ## Examples

      iex> get_owner(%Account{id: 1})
      %User{}

      iex> get_owner!(%Account{id: 2})
      nil

  """
  def get_owner(%Account{} = account) do
    from(
      u in User,
      join: m in assoc(u, :memberships),
      where: m.account_id == ^account.id and m.owner == true,
      order_by: :id,
      limit: 1
    )
    |> Repo.one()
  end

  alias Tq2.Accounts.Password

  @doc """
  Gets a single user by his token or email.
  Returns nil if a User with this token does not exist or the token is expired.
  ## Examples
      iex> get_user(token: "qCRc-NABnQgqX2oPiOThY..")
      %User{}
      iex> get_user(email: "some@email.com")
      %User{}
      iex> get_user(token: "qQdvYYT8gpHJVXrIdcDDc..")
      nil
  """
  def get_user(token: token), do: Password.get_user_by_token(token)
  def get_user(email: email), do: Repo.get_by(User, email: email)

  @doc """
  Creates a user.

  ## Examples

      iex> create_user(%Session{}, %{field: value})
      {:ok, %User{}}

      iex> create_user(%Session{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_user(%Session{account: account, user: user}, attrs \\ %{}) do
    attrs = Membership.put_create_user_attrs(account, attrs)

    %User{}
    |> User.create_changeset(attrs)
    |> Trail.insert(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Updates a user.

  ## Examples

      iex> update_user(%Session{}, user, %{field: new_value})
      {:ok, %User{}}

      iex> update_user(%Session{}, user, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_user(%Session{account: account, user: current_user}, %User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Trail.update(originator: current_user, meta: %{account_id: account.id})
  end

  @doc """
  Updates a user password.
  ## Examples
      iex> update_user_password(user, %{password: "newpass", password_confirmation: "newpass"})
      {:ok, %User{}}
      iex> update_user_password(user, %{password: "newpass", password_confirmation: "wrong"})
      {:error, %Ecto.Changeset{}}
  """
  def update_user_password(%User{} = user, attrs) do
    user
    |> User.password_reset_changeset(attrs)
    |> Trail.update(originator: user)
  end

  @doc """
  Deletes a user.

  ## Examples

      iex> delete_user(%Session{}, user)
      {:ok, %User{}}

      iex> delete_user(%Session{}, user)
      {:error, %Ecto.Changeset{}}

  """
  def delete_user(%Session{account: account, user: current_user}, %User{} = user) do
    Trail.delete(user, originator: current_user, meta: %{account_id: account.id})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user changes.

  ## Examples

      iex> change_user(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user(%User{} = user, attrs \\ %{}) do
    User.changeset(user, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking user password changes.
  ## Examples
      iex> change_user_password(user)
      %Ecto.Changeset{source: %User{}}
  """
  def change_user_password(%User{} = user) do
    User.password_reset_changeset(user, %{})
  end

  @doc """
  Gets a session with the given account and user id
  Returns nil when any of the arguments is nil
  Raises `Ecto.NoResultsError` if the User or the Account does not exist.
  ## Examples
      iex> get_current_session(1, 2)
      %Session{}
      iex> get_current_session(nil, 1)
      nil
      iex> get_current_session(2, 2)
      ** (Ecto.NoResultsError)
  """
  def get_current_session(account_id, user_id) do
    Session.get_session(account_id, user_id)
  end

  alias Tq2.Accounts.Auth

  @doc """
  Authenticates a user.
  ## Examples
    iex> authenticate_by_email_and_password("john@doe.com", "123")
    {:ok, %User{}}
    iex> authenticate_by_email_and_password("john@doe.com", "wrong")
    {:error, :unauthorized}
  """
  def authenticate_by_email_and_password(email, password) do
    Auth.authenticate_by_email_and_password(email, password)
  end

  @doc """
  Sends password reset email to a user.
  ## Examples
      iex> password_reset(user)
      {:ok, %User{}}
  """
  def password_reset(user), do: Password.reset(user)

  @doc """
  Gets the account owner.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_account_owner!(%Account{id: 1})
      %User{}

      iex> get_account_owner!(%Account{id: 2})
      ** (Ecto.NoResultsError)

  """
  def get_account_owner!(%Account{} = account) do
    from(
      u in User,
      join: m in assoc(u, :memberships),
      where: m.account_id == ^account.id and m.owner == true
    )
    |> Repo.one!()
  end

  @doc """
  Gets a single license.

  Raises `Ecto.NoResultsError` if the License does not exist.

  ## Examples

      iex> get_license!(%Account{id: 1})
      %License{}

      iex> get_license!(%{customer_id: "cus_xxxx"})
      %License{}

      iex> get_license!(%Account{id: 2})
      ** (Ecto.NoResultsError)

      iex> get_license!(%{customer_id: "unknown"})
      ** (Ecto.NoResultsError)

  """
  def get_license!(%Account{} = account) do
    License
    |> Repo.get_by!(account_id: account.id)
    |> Map.put(:account, account)
  end

  def get_license!([{field, value}]) when field in [:customer_id, :subscription_id] do
    License
    |> join(:left, [l], a in assoc(l, :account))
    |> preload([l, a], account: a)
    |> Repo.get_by!(%{field => value})
  end

  @doc """
  Updates a license.

  ## Examples

      iex> update_license(%Session{}, license, %{field: new_value})
      {:ok, %License{}}

      iex> update_license(license, %{field: new_value})
      {:ok, %License{}}

      iex> update_license(%Session{}, license, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

      iex> update_license(license, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_license(%Session{account: account, user: user}, %License{} = license, attrs) do
    license
    |> License.changeset(attrs)
    |> Trail.update(originator: user, meta: %{account_id: account.id})
  end

  def update_license(%License{account: account} = license, attrs) do
    license
    |> License.changeset(attrs)
    |> Trail.update(meta: %{account_id: account.id})
  end

  @doc """
  Deletes a License.

  ## Examples

      iex> delete_license(%Session{})
      {:ok, %License{}}

      iex> delete_license(%Session{})
      {:error, %Ecto.Changeset{}}

  """
  def delete_license(%Session{account: account, user: user}) do
    account
    |> get_license!()
    |> Trail.delete(originator: user, meta: %{account_id: account.id})
  end

  alias Tq2.Accounts.Registration

  @doc """
  Gets a single registration.

  Raises `Ecto.NoResultsError` if the Registration does not exist.

  ## Examples

      iex> get_registration!("cd71ec95-cb01-4e9b-ae7a-4cf3adf83aee")
      %Registration{}

      iex> get_registration!("73a7cf97-3ddb-4921-9e33-8b46d175945b")
      ** (Ecto.NoResultsError)

  """
  def get_registration!(uuid) do
    Registration
    |> where([r], is_nil(r.accessed_at))
    |> join(:left, [r], a in assoc(r, :account))
    |> preload([r, a], account: a)
    |> Repo.get_by!(uuid: uuid)
  end

  @doc """
  Creates a registration.

  ## Examples

      iex> create_registration(%{field: "value"})
      {:ok, %Registration{}}

      iex> create_registration(%{field: "bad_value"})
      {:error, %Ecto.Changeset{}}

  """
  def create_registration(attrs) do
    %Registration{}
    |> Registration.create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a registration.

  ## Examples

      iex> update_registration(registration, %{name: "new_value"})
      {:ok, %Registration{}}

      iex> update_registration(registration, %{name: "bad_value"})
      {:error, %Ecto.Changeset{}}

  """
  def update_registration(%Registration{} = registration, attrs) do
    registration
    |> Registration.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Finish the registration, creates account and initial user.

  ## Examples

      iex> finish_registration(registration, %{name: "new_value"})
      {:ok, %{
        registration: %Registration{},
        user: %User{},
        account: %Account{}
      }}

      iex> finish_registration(registration, %{name: "bad_value"})
      {:error, %Ecto.Changeset{}}

  """
  def finish_registration(%Registration{} = registration, attrs) do
    registration
    |> Registration.password_changeset(attrs)
    |> Repo.update()
    |> put_country_data(attrs)
  end

  @doc """
  Mark the registration as accessed.

  ## Examples

      iex> access_registration(registration)
      {:ok, %Registration{}}

      iex> access_registration(registration)
      {:error, %Ecto.Changeset{}}

  """
  def access_registration(%Registration{} = registration) do
    registration
    |> Ecto.Changeset.change(%{accessed_at: DateTime.utc_now() |> DateTime.truncate(:second)})
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking registration changes.

  ## Examples

      iex> change_registration(registration)
      %Ecto.Changeset{source: %Registration{}}

  """
  def change_registration(%Registration{} = registration) do
    Registration.changeset(registration, %{})
  end

  defp put_country_data({:ok, registration}, extra_params) do
    account_attrs = registration_account_attributes(registration, extra_params)

    Multi.new()
    |> Multi.insert(:account, Account.create_changeset(%Account{}, account_attrs))
    |> Multi.insert(:store, &registration_store_changeset(registration, &1))
    |> Multi.insert(:user, &registration_user_changeset(registration, &1))
    |> Multi.update(:registration, &registration_account_changeset(registration, &1))
    |> Repo.transaction()
  end

  defp put_country_data({:error, changeset}, _), do: {:error, changeset}

  defp registration_account_attributes(registration, %{"country" => country, "time_zone" => tz}) do
    License.put_create_account_attrs(%{
      name: registration.name,
      status: "green",
      country: country,
      time_zone: time_zone_or_country_default(tz, country)
    })
  end

  defp registration_store_changeset(registration, %{account: %Account{} = account}) do
    slug = Tq2.Shops.Store.slugified(registration.name)

    attrs = %{
      name: registration.name,
      slug: slug,
      published: true,
      configuration: %{
        pickup: true,
        pickup_time_limit: dgettext("stores", "No limit")
      }
    }

    case Tq2.Shops.Store.changeset(account, %Tq2.Shops.Store{}, attrs) do
      %{valid?: true} = changeset ->
        changeset

      _ ->
        rand = :crypto.strong_rand_bytes(3) |> Base.url_encode64(padding: false)
        attrs = attrs |> Map.put(:slug, "#{slug}_#{rand}")

        Tq2.Shops.Store.changeset(account, %Tq2.Shops.Store{}, attrs)
    end
  end

  defp registration_user_changeset(registration, %{account: %Account{} = account}) do
    attrs =
      Membership.put_create_user_attrs(account, %{
        name: registration.name,
        lastname: registration.name,
        email: registration.email,
        password: registration.password,
        password_confirmation: registration.password,
        role: "owner"
      })

    User.create_changeset(%User{}, attrs)
  end

  defp registration_account_changeset(registration, %{account: %Account{} = account}) do
    Registration.account_changeset(registration, %{account_id: account.id})
  end
end
