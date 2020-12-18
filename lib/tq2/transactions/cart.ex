defmodule Tq2.Transactions.Cart do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.Account
  alias Tq2.Transactions.{Cart, Data, Line}
  alias Tq2.Sales.Customer

  schema "carts" do
    field :token, :string
    field :price_type, :string, default: "promotional"

    embeds_one :data, Data

    belongs_to :customer, Customer
    belongs_to :account, Account

    has_many :lines, Line

    timestamps()
  end

  @price_types ~w(promotional regular)

  @doc false
  def changeset(%Cart{} = cart, attrs, %Account{} = account) do
    cart
    |> cast(attrs, [:token, :price_type, :customer_id])
    |> cast_embed(:data)
    |> put_account(account)
    |> validate_required([:token, :price_type])
    |> validate_length(:token, max: 255)
    |> validate_inclusion(:price_type, @price_types)
    |> unique_constraint(:token)
    |> assoc_constraint(:customer)
    |> assoc_constraint(:account)
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
