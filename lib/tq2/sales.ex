defmodule Tq2.Sales do
  @moduledoc """
  The Sales context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Tq2.{Repo, Trail}
  alias Tq2.Sales.Customer
  alias Tq2.Accounts.{Account, Session}

  @doc """
  Gets a single customer by id.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer!(123)
      %Customer{}

      iex> get_customer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(id) when is_integer(id) do
    Customer |> Repo.get!(id)
  end

  @doc """
  Gets a single customer by token or by email OR phone.

  Returns nil if the Customer does not exist.

  ## Examples

      iex> get_customer("some_token")
      %Customer{}

      iex> get_customer("invalid_token")
      nil

      iex> get_customer(email: "some@email.com", phone: "555-5555")
      %Customer{}

      iex> get_customer(email: "invalid@email.com", phone: "XXX-XXXX")
      nil

  """
  def get_customer(token) when is_binary(token) do
    Customer
    |> join(:inner, [c], t in assoc(c, :tokens))
    |> where([c, t], t.value == ^token)
    |> Repo.one()
  end

  def get_customer(opts) when is_list(opts) do
    email = Customer.canonized_email(opts[:email]) || "invalid"
    phone = Customer.canonized_phone(opts[:phone]) || "invalid"

    Customer
    |> where([c], c.email == ^email)
    |> or_where([c], c.phone == ^phone)
    |> Repo.one()
  end

  @doc """
  Check if customer exists by token.

  Returns true if Customer exists.

  ## Examples

      iex> customer_exists?("some_token")
      true

      iex> customer_exists?("invalid_token")
      false
  """
  def customer_exists?(token) when is_binary(token) do
    Customer
    |> join(:inner, [c], t in assoc(c, :tokens))
    |> where([c, t], t.value == ^token)
    |> Repo.exists?()
  end

  @doc """
  Creates a customer.

  ## Examples

      iex> create_customer(%{field: value})
      {:ok, %Customer{}}

      iex> create_customer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer(attrs, store \\ nil) do
    %Customer{}
    |> Customer.changeset(attrs, store)
    |> Repo.insert()
  end

  @doc """
  Creates a customer and assigns new token to his cart.

  ## Examples

      iex> create_customer(%{field: value}, %Store{}, "123", "234")
      {:ok, %Customer{}}

      iex> create_customer(%{field: bad_value}, %Store{}, "123", "333")
      {:error, %Ecto.Changeset{}}

  """
  def create_customer(attrs, %Tq2.Shops.Store{} = store, token, old_token) do
    cart = Tq2.Transactions.get_cart(store.account, old_token)

    result =
      Multi.new()
      |> Multi.insert(:customer, Customer.changeset(%Customer{}, attrs, store))
      |> Multi.update(:cart, Tq2.Transactions.change_cart(store.account, cart, %{token: token}))
      |> Repo.transaction()

    case result do
      {:ok, %{customer: customer}} ->
        {:ok, customer}

      {:error, :customer, changeset, _} ->
        {:error, changeset}
    end
  end

  @doc """
  Updates a customer.

  ## Examples

      iex> update_customer(customer, %{field: new_value})
      {:ok, %Customer{}}

      iex> update_customer(customer, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_customer(%Customer{} = customer, attrs, store \\ nil) do
    customer
    |> Customer.update_changeset(attrs, store)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(customer)
      %Ecto.Changeset{source: %Customer{}}

  """
  def change_customer(%Customer{} = customer, attrs \\ %{}, store \\ nil) do
    Customer.changeset(customer, attrs, store)
  end

  alias Tq2.Sales.Order
  alias Tq2.Transactions.Cart

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders(%Account{}, %{})
      [%Order{}, ...]

  """
  def list_orders(account, params) do
    Order
    |> where(account_id: ^account.id)
    |> join(:left, [o], cart in assoc(o, :cart))
    |> join(:left, [o, cart], c in assoc(cart, :customer))
    |> preload([o, cart, c], cart: cart, customer: c)
    |> order_by([o], desc: o.inserted_at)
    |> Repo.paginate(params)
  end

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_unexpired_orders(%Account{}, %{})
      [%Order{}, ...]

  """
  def list_unexpired_orders(account, params) do
    now = DateTime.utc_now()

    Order
    |> where([o], o.account_id == ^account.id and o.promotion_expires_at > ^now)
    |> join(:left, [o], cart in assoc(o, :cart))
    |> where([o, cart], cart.price_type == "promotional")
    |> join(:left, [o, cart], c in assoc(cart, :customer), as: :customer)
    |> join(:left, [o, cart, c], t in assoc(c, :tokens))
    |> join(
      :inner_lateral,
      [o, cart, c, t],
      latest_t in subquery(
        from Tq2.Shares.Token,
          where: [customer_id: parent_as(:customer).id],
          order_by: [desc: :id],
          limit: 1,
          select: [:id]
      ),
      on: latest_t.id == t.id
    )
    |> preload([o, cart, c, t], cart: cart, customer: {c, tokens: t})
    |> order_by([o], asc: o.promotion_expires_at)
    |> Repo.paginate(params)
  end

  @doc """
  Returns the amount of sales for the given period.

  ## Examples

      iex> orders_sale_amount(%Account{}, :daily)
      %Money{}

  """
  def orders_sale_amount(account, period \\ :daily) do
    {from, to} = range_for(period)
    currency = Tq2.Utils.CountryCurrency.currency(account.country)

    amount =
      Order
      |> where([o], o.account_id == ^account.id and o.status == "completed")
      |> where([o], o.inserted_at >= ^from and o.inserted_at <= ^to)
      |> join(:left, [o], pc in Cart, on: pc.id == o.cart_id and pc.price_type == "promotional")
      |> join(:left, [o, pc], pl in assoc(pc, :lines))
      |> join(:left, [o], rc in Cart, on: rc.id == o.cart_id and rc.price_type == "regular")
      |> join(:left, [o, pc, pl, rc], rl in assoc(rc, :lines))
      |> select(
        [o, pc, pl, rc, rl],
        coalesce(
          sum(fragment("(?->>'amount')::integer * ?", pl.promotional_price, pl.quantity)),
          0
        ) +
          coalesce(sum(fragment("(?->>'amount')::integer * ?", rl.price, rl.quantity)), 0)
      )
      |> Repo.one()

    Money.new(amount, currency)
  end

  @doc """
  Returns the amount of orders for the given period, grouped by status and price type.

  ## Examples

      iex> orders_by_status_count(%Account{}, :daily)
      [{"completed", "regular", 4}, {"completed", "promotional", 6}]

  """
  def orders_by_status_count(account, period \\ :daily) do
    {from, to} = range_for(period)

    Order
    |> where([o], o.account_id == ^account.id)
    |> where([o], o.inserted_at >= ^from and o.inserted_at <= ^to)
    |> join(:left, [o], c in assoc(o, :cart))
    |> group_by([o, c], [o.status, c.price_type])
    |> select([o, c], {o.status, c.price_type, count(o.id)})
    |> Repo.all()
  end

  @doc """
  Gets a single order.

  Raises `Ecto.NoResultsError` if the Order does not exist.

  ## Examples

      iex> get_order!(%Account{}, 123)
      %Order{}

      iex> get_order!(%Account{}, 456)
      ** (Ecto.NoResultsError)

  """
  def get_order!(account, id) do
    order =
      Order
      |> where(account_id: ^account.id)
      |> join(:left, [o], c in assoc(o, :cart))
      |> join(:left, [o], customer in assoc(o, :customer))
      |> join(:left, [o, c], l in assoc(c, :lines))
      |> join(:left, [o, c], p in assoc(c, :payments))
      |> join(:left, [o], parents in assoc(o, :parents))
      |> join(:left, [o], children in assoc(o, :children))
      |> join(:left, [o, c, customer, l, p, parents], p_c in assoc(parents, :customer))
      |> join(:left, [o, c, customer, l, p, parents, children], c_c in assoc(children, :customer))
      |> join(:left, [o], comments in assoc(o, :comments))
      |> preload([o, c, customer, l, p, parents, children, p_c, c_c, comments],
        cart: {c, customer: customer, lines: l, payments: p},
        customer: customer,
        comments: comments,
        parents: {parents, customer: p_c},
        children: {children, customer: c_c}
      )
      |> Repo.get!(id)

    %{order | account: account}
  end

  @doc """
  Gets a single order, only if on promotion.

  Returns nil if the Order does not exist.

  ## Examples

      iex> get_promotional_order_for(%Account{}, %Customer{id: 1})
      %Order{}

      iex> get_promotional_order_for(%Account{}, %Customer{id: 2})
      nil

  """
  def get_promotional_order_for(account, customer) do
    now = DateTime.utc_now()

    Order
    |> join(:left, [o], c in assoc(o, :customer))
    |> join(:left, [o, c], cart in assoc(o, :cart))
    |> join(:left, [o, c, cart], t in assoc(o, :originator_ties))
    |> where(
      [o, c, cart, t],
      o.account_id == ^account.id and
        c.id == ^customer.id and
        cart.price_type == "promotional" and
        o.promotion_expires_at > ^now
    )
    |> group_by([o], o.id)
    |> order_by([o, c, cart, t], asc: count(t.id), asc: o.promotion_expires_at)
    |> first()
    |> Repo.one()
  end

  @doc """
  Gets a single not referred pending order to be expired.

  Returns nil if the Order does not exist.

  ## Examples

      iex> get_not_referred_pending_order(123)
      %Order{}

      iex> get_not_referred_pending_order(456)
      nil

  """
  def get_not_referred_pending_order(id) do
    Order
    |> join(:left, [o], account in assoc(o, :account))
    |> join(:left, [o], t in assoc(o, :originator_ties))
    |> join(:left, [o], cart in assoc(o, :cart))
    |> join(:left, [o, account, t, cart], c in assoc(cart, :customer))
    |> join(:left, [o, account, t, cart], l in assoc(cart, :lines))
    |> join(:left, [o, account, t, cart], p in assoc(cart, :payments))
    |> where(
      [o, account, t, cart],
      o.status == "pending" and
        cart.price_type == "promotional" and
        is_nil(t.id)
    )
    |> preload(
      [o, account, t, cart, c, l, p],
      account: account,
      cart: {cart, lines: l, order: o, payments: p},
      customer: c
    )
    |> Repo.get(id)
  end

  @doc """
  Gets the most recent order for customer with the given token.

  Returns nil if none is available.

  ## Examples

      iex> get_latest_order(%Account{}, "some token")
      %Order{}

      iex> get_latest_order(%Account{}, "other token")
      nil

  """
  def get_latest_order(account, token) do
    Order
    |> where(account_id: ^account.id)
    |> join(:left, [o], c in assoc(o, :cart))
    |> join(:left, [o], customer in assoc(o, :customer))
    |> join(:left, [o, c, customer], t in assoc(customer, :tokens))
    |> where([o, c, customer, t], t.value == ^token)
    |> preload([o, c, customer], cart: {c, customer: customer}, customer: customer)
    |> order_by(asc: :inserted_at)
    |> last()
    |> Repo.one()
  end

  @doc """
  Creates a order.

  ## Examples

      iex> create_order(%Account{}, %{field: value})
      {:ok, %Order{}}

      iex> create_order(%Account{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_order(%Account{} = account, attrs) do
    account
    |> Order.changeset(%Order{}, attrs)
    |> Repo.insert()
    |> Order.update_visit()
    |> Order.notify()
    |> Order.schedule_expiration_task()
  end

  @doc """
  Updates a order.

  ## Examples

      iex> update_order(%Session{}, order, %{field: new_value})
      {:ok, %Order{}}

      iex> update_order(%Session{}, order, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_order(%Session{account: account, user: user}, %Order{} = order, attrs) do
    account
    |> Order.changeset(order, attrs)
    |> Trail.update(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Deletes a Order.

  ## Examples

      iex> delete_order(%Session{}, order)
      {:ok, %Order{}}

      iex> delete_order(%Session{}, order)
      {:error, %Ecto.Changeset{}}

  """
  def delete_order(%Session{account: account, user: user}, %Order{} = order) do
    Trail.delete(order, originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(%Account{}, %Order{}, %{})
      %Ecto.Changeset{source: %Order{}}

  """
  def change_order(%Account{} = account, %Order{} = order, attrs) do
    account |> Order.changeset(order, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking order changes.

  ## Examples

      iex> change_order(%Account{}, %Order{})
      %Ecto.Changeset{source: %Order{}}

  """
  def change_order(%Account{} = account, %Order{} = order) do
    account |> change_order(order, %{})
  end

  def change_order(%Account{} = account, attrs) do
    account |> change_order(%Order{}, attrs)
  end

  defp range_for(:daily) do
    now = DateTime.utc_now()

    {Timex.beginning_of_day(now), Timex.end_of_day(now)}
  end
end
