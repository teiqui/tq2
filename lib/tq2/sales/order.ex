defmodule Tq2.Sales.Order do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.Account
  alias Tq2.Repo
  alias Tq2.Sales.{Data, Order}
  alias Tq2.Transactions.Cart

  schema "orders" do
    field :status, :string, default: "pending"
    field :promotion_expires_at, :utc_datetime
    field :lock_version, :integer, default: 0

    embeds_one :data, Data

    belongs_to :cart, Cart
    belongs_to :account, Account

    has_one :customer, through: [:cart, :customer]
    has_one :visit, through: [:cart, :visit]
    has_one :referral_customer, through: [:visit, :referral_customer]

    timestamps()
  end

  @statuses ~w(pending processing completed canceled)

  @doc false
  def changeset(%Account{} = account, %Order{} = order, attrs) do
    order
    |> cast(attrs, [:status, :promotion_expires_at, :cart_id, :lock_version])
    |> cast_embed(:data)
    |> cast_assoc(:cart, with: {Cart, :changeset, [account]})
    |> put_account(account)
    |> validate_required([:status, :promotion_expires_at])
    |> validate_inclusion(:status, @statuses)
    |> optimistic_lock(:lock_version)
    |> assoc_constraint(:cart)
    |> assoc_constraint(:account)
  end

  @doc false
  def update_visit({:ok, %{cart_id: cart_id} = order}) do
    visit = Tq2.Analytics.get_visit!(cart_id: cart_id)

    visit
    |> change()
    |> put_change(:order_id, order.id)
    |> Repo.update!()

    {:ok, order}
  end

  def update_visit({:error, _changeset} = result), do: result

  @doc false
  def notify({:ok, order}) do
    order = Repo.preload(order, [:account, :customer, cart: [lines: :item]])
    owner = Tq2.Accounts.get_owner(order.account)

    Tq2.Notifications.send_new_order(order, order.customer)
    Tq2.Notifications.send_new_order(order, owner)

    {:ok, order}
  end

  def notify({:error, _changeset} = result), do: result

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
