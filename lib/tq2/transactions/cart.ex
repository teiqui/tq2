defmodule Tq2.Transactions.Cart do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.Account
  alias Tq2.Analytics.Visit
  alias Tq2.Payments.Payment
  alias Tq2.Sales.{Customer, Order}
  alias Tq2.Transactions.{Cart, Data, Line}

  schema "carts" do
    field :token, :string
    field :price_type, :string, default: "promotional"
    field :referred, :boolean, default: false, virtual: true

    embeds_one :data, Data

    belongs_to :customer, Customer
    belongs_to :visit, Visit
    belongs_to :account, Account

    has_one :order, Order

    has_many :lines, Line
    has_many :payments, Payment

    timestamps type: :utc_datetime
  end

  @price_types ~w(promotional regular)

  @doc false
  def changeset(%Cart{} = cart, attrs, %Account{} = account) do
    cart
    |> cast(attrs, [:token, :price_type, :customer_id, :visit_id])
    |> cast_embed(:data)
    |> put_account(account)
    |> validate()
  end

  @doc false
  def handing_changeset(%Cart{} = cart, attrs, %Account{} = account) do
    cart
    |> cast(attrs, [:token, :price_type, :customer_id, :visit_id])
    |> cast_embed(:data, required: true)
    |> put_account(account)
    |> validate()
  end

  defp validate(%Ecto.Changeset{} = changeset) do
    changeset
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
    |> Enum.filter(&(&1.status == "paid"))
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
    |> Enum.map(& &1.amount)
    |> Enum.reduce(fn amount, total -> Money.add(amount, total) end)
  end

  def total(%Cart{data: %{handing: "delivery", shipping: %{price: price}}} = cart) do
    %{cart | data: %{}}
    |> total()
    |> Money.add(price)
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
    Tq2.Utils.CountryCurrency.currency(country)
  end

  def currency(%Cart{lines: lines}) do
    lines |> List.first() |> Map.get(:price) |> Map.get(:currency) |> Atom.to_string()
  end

  def shipping(%Cart{data: %{shipping: shipping}}), do: shipping
  def shipping(%Cart{}), do: nil

  def can_be_copied?(store, %Cart{data: nil} = cart, other) do
    can_be_copied?(store, %{cart | data: %{copied: false}}, other)
  end

  def can_be_copied?(store, %Cart{data: %{copied: false}}, other) do
    cart_shipping_is_available_in_store?(other, store) &&
      cart_payment_is_available_in_store?(other, store) &&
      cart_customer_is_valid?(other, store)
  end

  def can_be_copied?(_store, _cart, _other), do: false

  defp cart_payment_is_available_in_store?(cart, store) do
    cart.data.payment in Tq2.Shops.Store.available_payment_methods(store)
  end

  defp cart_shipping_is_available_in_store?(cart, store) do
    case cart.data && cart.data.shipping do
      nil ->
        true

      shipping ->
        !!Enum.find(store.configuration.shippings, &(&1.id == shipping.id))
    end
  end

  defp cart_customer_is_valid?(%{customer: customer}, store) do
    customer
    |> Tq2.Sales.change_customer(%{}, store)
    |> Map.get(:valid?)
  end

  def extract_data(store, %Cart{data: data}, %Cart{data: previous_data}) do
    shipping = extract_shipping(store, previous_data)

    %{
      id: data && data.id,
      handing: previous_data.handing,
      payment: previous_data.payment,
      copied: true,
      shipping: shipping
    }
  end

  defp extract_shipping(_store, nil), do: nil
  defp extract_shipping(_store, %{shipping: nil}), do: nil

  defp extract_shipping(store, %{shipping: shipping}) do
    case Enum.find(store.configuration.shippings, &(&1.id == shipping.id)) do
      nil -> nil
      shipping -> Map.from_struct(shipping)
    end
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
