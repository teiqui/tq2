defmodule Tq2.Notifications.SubscriptionUser do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.User
  alias Tq2.Notifications.{Subscription, SubscriptionUser}

  schema "subscriptions_users" do
    belongs_to :subscription, Subscription
    belongs_to :user, User

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%SubscriptionUser{} = subscription_user, attrs) do
    subscription_user
    |> cast(attrs, [:user_id])
    |> validate_required([:user_id])
  end
end
