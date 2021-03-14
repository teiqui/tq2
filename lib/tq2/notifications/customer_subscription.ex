defmodule Tq2.Notifications.CustomerSubscription do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Notifications.{Subscription, CustomerSubscription}
  alias Tq2.Sales.Customer

  schema "customers_subscriptions" do
    belongs_to :subscription, Subscription
    belongs_to :customer, Customer

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%CustomerSubscription{} = subscription_customer, attrs) do
    subscription_customer
    |> cast(attrs, [:customer_id])
    |> validate_required([:customer_id])
  end
end
