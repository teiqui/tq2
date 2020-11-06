defmodule Tq2.Accounts.Membership do
  use Ecto.Schema
  import Ecto.Changeset

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
    |> validate_required([:default, :account_id, :user_id])
    |> assoc_constraint(:account)
    |> assoc_constraint(:user)
  end
end
