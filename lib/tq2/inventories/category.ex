defmodule Tq2.Inventories.Category do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Inventories.{Category, Item}
  alias Tq2.Accounts.Account
  alias Tq2.Utils.TrimmedString

  schema "categories" do
    field :name, TrimmedString
    field :ordinal, :integer, default: 0
    field :lock_version, :integer, default: 0

    belongs_to :account, Account

    has_many :items, Item

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%Account{} = account, %Category{} = category, attrs) do
    category
    |> cast(attrs, [:name, :ordinal, :lock_version])
    |> put_account(account)
    |> validate_required([:name, :ordinal])
    |> validate_length(:name, max: 255)
    |> validate_number(:ordinal, greater_than_or_equal_to: 0, less_than: 2_147_483_648)
    |> unsafe_validate_unique([:name, :account_id], Tq2.Repo)
    |> unique_constraint([:name, :account_id])
    |> assoc_constraint(:account)
    |> optimistic_lock(:lock_version)
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
