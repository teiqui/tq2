defmodule Tq2.Sales.Order do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.Account
  alias Tq2.Sales.{Data, Order}
  alias Tq2.Transactions.Cart

  schema "orders" do
    field :status, :string, default: "pending"
    field :promotion_expires_at, :utc_datetime
    field :lock_version, :integer, default: 0

    embeds_one :data, Data

    belongs_to :cart, Cart
    belongs_to :account, Account

    timestamps()
  end

  @statuses ~w(pending processing completed canceled)

  @doc false
  def changeset(%Account{} = account, %Order{} = order, attrs) do
    order
    |> cast(attrs, [:status, :promotion_expires_at, :lock_version])
    |> cast_embed(:data)
    |> cast_assoc(:cart, with: {Cart, :changeset, [account]})
    |> put_account(account)
    |> validate_required([:status, :promotion_expires_at])
    |> validate_inclusion(:status, @statuses)
    |> optimistic_lock(:lock_version)
    |> assoc_constraint(:cart)
    |> assoc_constraint(:account)
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
