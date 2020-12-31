defmodule Tq2.Transactions.Cart do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.Account
  alias Tq2.Analytics.Visit
  alias Tq2.Payments.Payment
  alias Tq2.Payments.Payment
  alias Tq2.Sales.{Customer, Order}
  alias Tq2.Transactions.{Cart, Data, Line}

  schema "carts" do
    field :token, :string
    field :price_type, :string, default: "promotional"

    embeds_one :data, Data

    belongs_to :customer, Customer
    belongs_to :visit, Visit
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
    |> cast(attrs, [:token, :price_type, :customer_id, :visit_id])
    |> cast_embed(:data)
    |> put_account(account)
    |> validate_required([:token, :price_type])
    |> validate_length(:token, max: 255)
    |> validate_inclusion(:price_type, @price_types)
    |> unique_constraint(:token)
    |> assoc_constraint(:customer)
    |> assoc_constraint(:visit)
    |> assoc_constraint(:account)
  end

  def paid?(%Cart{} = cart) do
    cart = Tq2.Repo.preload(cart, :payments)

    cart.payments
    |> Enum.filter(&(&1.status == "paid"))
    |> paid_in_full?(cart)
  end

  def pending_amount(%Cart{} = cart) do
    cart = Tq2.Repo.preload(cart, :payments)
    currency = currency(cart)

    cart.payments
    |> payments_amount(currency)
    |> Money.multiply(-1)
    |> Money.add(total(cart))
  end

  def paid_in_full?([], _), do: false

  def paid_in_full?(payments, cart) do
    currency = currency(cart)

    payments
    |> payments_amount(currency)
    |> Kernel.>=(total(cart))
  end

  def payments_amount([], currency) do
    Money.new(0, currency)
  end

  def payments_amount(payments, _) do
    payments
    |> Enum.filter(&(&1.status == "paid"))
    |> Enum.map(& &1.amount)
    |> Enum.reduce(fn amount, total -> Money.add(amount, total) end)
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

  def currency(%Cart{account: %Account{country: country}}) do
    Account.currency(country)
  end

  def currency(%Cart{lines: lines}) do
    lines |> List.first() |> Map.get(:price) |> Map.get(:currency) |> Atom.to_string()
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
