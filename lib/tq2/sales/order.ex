defmodule Tq2.Sales.Order do
  use Ecto.Schema

  import Ecto.Changeset
  import Tq2Web.Gettext, only: [dgettext: 2]

  alias Tq2.Accounts.Account
  alias Tq2.Messages.Comment
  alias Tq2.Repo
  alias Tq2.Sales.{Data, Order, Tie}
  alias Tq2.Transactions.Cart

  schema "orders" do
    field :status, :string, default: "pending"
    field :promotion_expires_at, :utc_datetime
    field :confirmed, :boolean, virtual: true
    field :lock_version, :integer, default: 0

    embeds_one :data, Data

    belongs_to :cart, Cart
    belongs_to :account, Account

    has_one :customer, through: [:cart, :customer]
    has_one :visit, through: [:cart, :visit]
    has_one :referral_customer, through: [:visit, :referral_customer]
    has_one :store, through: [:account, :store]

    has_many :ties, Tie
    has_many :originator_ties, Tie, foreign_key: :originator_id
    has_many :children, through: [:originator_ties, :order]
    has_many :parents, through: [:ties, :originator]
    has_many :comments, Comment, preload_order: [asc: :inserted_at]

    timestamps type: :utc_datetime
  end

  @statuses ~w(pending processing completed canceled)

  @doc false
  def changeset(%Account{} = account, %Order{} = order, attrs) do
    order
    |> cast(attrs, [:status, :promotion_expires_at, :cart_id, :lock_version])
    |> cast_embed(:data)
    |> cast_assoc(:cart, with: {Cart, :changeset, [account]})
    |> cast_assoc(:ties)
    |> put_account(account)
    |> validate_required([:status, :promotion_expires_at])
    |> validate_inclusion(:status, @statuses)
    |> optimistic_lock(:lock_version)
    |> assoc_constraint(:cart)
    |> assoc_constraint(:account)
    |> validate_paid_on_completion()
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
  def notify({:ok, %Order{ties: %Ecto.Association.NotLoaded{}, confirmed: nil} = order}) do
    notify({:ok, %{order | confirmed: false}})
  end

  def notify({:ok, %Order{ties: [], confirmed: nil} = order}) do
    notify({:ok, %{order | confirmed: false}})
  end

  def notify({:ok, %Order{ties: [tie], confirmed: nil} = order}) do
    %{originator: originator} =
      Repo.preload(tie,
        originator: [:account, :customer, :parents, :children, cart: [lines: :item]]
      )

    Tq2.Notifications.send_promotion_confirmation(originator)

    notify({:ok, %{order | confirmed: true}})
  end

  def notify({:ok, %Order{confirmed: confirmed} = order}) when not is_nil(confirmed) do
    order = Repo.preload(order, [:account, :customer, cart: [lines: :item]])
    owner = Tq2.Accounts.get_owner(order.account)

    Tq2.Notifications.send_new_order(order, order.customer)
    Tq2.Notifications.send_new_order(order, owner)
    Tq2.Notifications.notify_new_order(order, owner)

    {:ok, order}
  end

  def notify({:error, _changeset} = result), do: result

  def schedule_expiration_task({:ok, %Order{cart: %Cart{price_type: "promotional"}} = order}) do
    Exq.enqueue_at(Exq, "default", order.promotion_expires_at, Tq2.Workers.OrdersJob, [order.id])

    {:ok, order}
  end

  def schedule_expiration_task(result), do: result

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end

  defp validate_paid_on_completion(
         %Ecto.Changeset{
           changes: %{status: "completed", data: %Ecto.Changeset{changes: %{paid: true}}}
         } = changeset
       ) do
    changeset
  end

  defp validate_paid_on_completion(
         %Ecto.Changeset{changes: %{status: "completed"}, data: %{data: data}} = changeset
       ) do
    case data && data.paid do
      true ->
        changeset

      _ ->
        add_error(
          changeset,
          :status,
          dgettext("orders", "To complete an order must be fully paid.")
        )
    end
  end

  defp validate_paid_on_completion(changeset), do: changeset
end
