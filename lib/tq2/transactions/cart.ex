defmodule Tq2.Transactions.Cart do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.Account
  alias Tq2.Payments.Payment
  alias Tq2.Sales.{Customer, Order}
  alias Tq2.Transactions.{Cart, Data, Line}

  schema "carts" do
    field :token, :string
    field :price_type, :string, default: "promotional"

    embeds_one :data, Data

    belongs_to :customer, Customer
    belongs_to :account, Account

    has_one :order, Order

    has_many :lines, Line
    has_many :payments, Payment

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

  def total(%Cart{} = cart) do
    cart.lines
    |> Enum.map(&line_total(cart, &1))
    |> Enum.reduce(fn price, total -> Money.add(price, total) end)
  end

  def line_total(%Cart{price_type: "promotional"}, line) do
    Money.multiply(line.promotional_price, line.quantity)
  end

  def line_total(_, line) do
    Money.multiply(line.price, line.quantity)
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
