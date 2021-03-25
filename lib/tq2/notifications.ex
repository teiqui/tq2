defmodule Tq2.Notifications do
  import Ecto.Query, warn: false

  alias Tq2.Accounts.User
  alias Tq2.Messages.Comment
  alias Tq2.Notifications.{Mailer, Email}
  alias Tq2.Repo
  alias Tq2.Sales.{Customer, Order}
  alias Tq2.Transactions.Cart

  @doc """
  Schedule send password reset email

  ## Examples

      iex> send_password_reset(%User{})
      %Bamboo.Email{}

  """
  def send_password_reset(%User{} = user) do
    user
    |> Email.password_reset()
    |> deliver_later()
  end

  @doc """
  Schedule send new order email

  Returns nil if the recipient has no address to send to

  ## Examples

      iex> send_new_order(%Order{}, %Customer{})
      %Bamboo.Email{}

      iex> send_new_order(%Order{}, %User{})
      %Bamboo.Email{}

  """
  def send_new_order(%Order{} = order, recipient) do
    order
    |> Email.new_order(recipient)
    |> deliver_later()
  end

  @doc """
  Schedule send promotion confirmation email

  Returns nil if the recipient has no address to send to

  ## Examples

      iex> send_promotion_confirmation(%Order{})
      %Bamboo.Email{}

  """
  def send_promotion_confirmation(%Order{} = order) do
    order
    |> Email.promotion_confirmation()
    |> deliver_later()
  end

  @doc """
  Schedule send expired promotion email

  Returns nil if the recipient has no address to send to

  ## Examples

      iex> send_expired_promotion(%Order{})
      %Bamboo.Email{}

  """
  def send_expired_promotion(%Order{} = order) do
    order
    |> Email.expired_promotion()
    |> deliver_later()
  end

  @doc """
  Schedule send license expired email

  ## Examples

      iex> send_license_expired(%User{})
      %Bamboo.Email{}

  """
  def send_license_expired(%User{} = user) do
    user
    |> Email.license_expired()
    |> deliver_later()
  end

  @doc """
  Schedule send license near to expire email

  ## Examples

      iex> send_license_near_to_expire(%User{})
      %Bamboo.Email{}

  """
  def send_license_near_to_expire(%User{} = user) do
    user
    |> Email.license_near_to_expire()
    |> deliver_later()
  end

  @doc """
  Schedule job to send a new order web push notification

  ## Examples

      iex> notify_new_order(%Order{}, %User{})
      {:ok, %Order{}}

  """
  def notify_new_order(%Order{} = order, nil), do: {:ok, order}

  def notify_new_order(%Order{} = order, user) do
    Exq.enqueue(Exq, "default", Tq2.Workers.NotificationsJob, [
      "new_order",
      order.account_id,
      order.id,
      user.id
    ])

    {:ok, order}
  end

  @doc """
  Schedule job to send a new comment web push notification

  ## Examples

      iex> notify_new_comment(%Comment{})
      {:ok, %Comment{}}

  """
  def notify_new_comment(%Comment{order: order, customer: customer} = comment) do
    Exq.enqueue(Exq, "default", Tq2.Workers.NotificationsJob, [
      "new_comment",
      order.account_id,
      order.id,
      customer.id,
      comment.id
    ])

    {:ok, comment}
  end

  alias Tq2.Notifications.Subscription

  @doc """
  Gets a single subscription.

  Returns nil if the Subscription does not exist.

  ## Examples

      iex> get_subscription!(%{"data" => %{"endpoint" => "https://example.com"}})
      %Subscription{}

      iex> get_subscription!(%{"data" => %{"endpoint" => "https://none.com"}})
      nil

  """
  def get_subscription(params) do
    hash = Subscription.hash(params)

    Subscription
    |> subscription_query(params)
    |> Repo.get_by(hash: hash)
  end

  @doc """
  Creates a subscription.

  ## Examples

      iex> create_subscription(%{field: value})
      {:ok, %Subscription{}}

      iex> create_subscription(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_subscription(%{"subscription_user" => _} = attrs) do
    attrs = Subscription.create_params(attrs)

    %Subscription{}
    |> Subscription.user_create_changeset(attrs)
    |> Repo.insert()
  end

  def create_subscription(%{"customer_subscription" => _} = attrs) do
    attrs = Subscription.create_params(attrs)

    %Subscription{}
    |> Subscription.customer_create_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a subscription.

  ## Examples

      iex> update_subscription(subscription, %{field: new_value})
      {:ok, %Subscription{}}

      iex> update_subscription(subscription, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_subscription(%Subscription{} = subscription, attrs) do
    subscription
    |> Subscription.update_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Schedule send cart reminder

  ## Examples

      iex> send_cart_reminder(%Cart{}, %Customer{})
      %Bamboo.Email{}

  """
  def send_cart_reminder(%Cart{} = cart, %Customer{} = customer) do
    cart
    |> Email.cart_reminder(customer)
    |> deliver_later()
  end

  defp deliver_later(nil), do: nil
  defp deliver_later(email), do: Mailer.deliver_later!(email)

  defp subscription_query(query, %{"subscription_user" => %{"user_id" => user_id}}) do
    query
    |> join(:inner, [s], su in assoc(s, :subscription_user))
    |> where([s, su], su.user_id == ^user_id)
  end

  defp subscription_query(query, %{"customer_subscription" => %{"customer_id" => customer_id}}) do
    query
    |> join(:inner, [s], su in assoc(s, :customer_subscription))
    |> where([s, su], su.customer_id == ^customer_id)
  end
end
