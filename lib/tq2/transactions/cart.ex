defmodule Tq2.Transactions.Cart do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.Account
  alias Tq2.Transactions.Cart
  alias Tq2.Sales.Customer

  schema "carts" do
    belongs_to :customer, Customer
    belongs_to :account, Account

    timestamps()
  end

  @doc false
  def changeset(%Account{} = account, %Cart{} = cart, attrs) do
    cart
    |> cast(attrs, [:customer_id])
    |> put_account(account)
    |> assoc_constraint(:customer)
    |> assoc_constraint(:account)
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
