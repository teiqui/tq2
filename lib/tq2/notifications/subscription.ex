defmodule Tq2.Notifications.Subscription do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Notifications.{CustomerSubscription, Data, Subscription, SubscriptionUser}

  schema "subscriptions" do
    field :hash, :string
    field :error_count, :integer, default: 0

    embeds_one :data, Data, on_replace: :update

    has_one :subscription_user, SubscriptionUser
    has_one :customer_subscription, CustomerSubscription

    timestamps type: :utc_datetime
  end

  @doc false
  def user_create_changeset(%Subscription{} = subscription, attrs) do
    subscription
    |> validation(attrs)
    |> cast_assoc(:subscription_user, required: true)
  end

  @doc false
  def customer_create_changeset(%Subscription{} = subscription, attrs) do
    subscription
    |> validation(attrs)
    |> cast_assoc(:customer_subscription, required: true)
  end

  @doc false
  def update_changeset(%Subscription{} = subscription, attrs) do
    subscription
    |> validation(attrs)
  end

  @doc false
  def hash(%{"data" => %{"endpoint" => endpoint, "keys" => %{"auth" => auth}}}) do
    :crypto.hash(:sha256, [endpoint, auth]) |> Base.encode16() |> String.downcase()
  end

  @doc false
  def create_params(attrs) do
    attrs
    |> Map.put("hash", hash(attrs))
    |> cast_expiration_time()
  end

  defp cast_expiration_time(%{"data" => %{"expirationTime" => time} = data} = attrs)
       when is_nil(time) do
    {_time, data} = Map.pop(data, "expirationTime")

    Map.put(attrs, "data", data)
  end

  defp cast_expiration_time(%{"data" => %{"expirationTime" => time} = data} = attrs) do
    {_time, data} = Map.pop(data, "expirationTime")
    data = Map.put(data, "expiration_time", DateTime.from_unix!(time, :millisecond))

    Map.put(attrs, "data", data)
  end

  defp cast_expiration_time(attrs), do: attrs

  defp validation(subscription, attrs) do
    subscription
    |> cast(attrs, [:hash, :error_count])
    |> cast_embed(:data)
    |> validate_required([:hash, :data])
    |> unsafe_validate_unique(:hash, Tq2.Repo)
    |> unique_constraint(:hash)
  end
end
