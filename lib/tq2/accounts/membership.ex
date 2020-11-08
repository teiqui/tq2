defmodule Tq2.Accounts.Membership do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query, warn: false

  alias Tq2.Accounts.{Account, User}

  schema "memberships" do
    field :default, :boolean, default: false

    belongs_to :account, Account
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(membership, attrs) do
    membership
    |> cast(attrs, [:default, :account_id, :user_id])
    |> validate_required([:default])
    |> assoc_constraint(:account)
    |> assoc_constraint(:user)
  end

  def put_create_user_attrs(%Account{} = account, %{"email" => email} = attrs) do
    Map.put(attrs, "memberships", [%{"account_id" => account.id, "default" => default?(email)}])
  end

  def put_create_user_attrs(%Account{} = account, %{email: email} = attrs) do
    Map.put(attrs, :memberships, [%{account_id: account.id, default: default?(email)}])
  end

  defp default?(email) do
    !Tq2.Repo.get_by(User, email: email)
  end
end
