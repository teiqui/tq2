defmodule Tq2.Sales do
  @moduledoc """
  The Sales context.
  """

  import Ecto.Query, warn: false

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
  Creates a customer.

  ## Examples

      iex> create_customer(%{field: value})
      {:ok, %Customer{}}

      iex> create_customer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer(attrs) do
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(customer)
      %Ecto.Changeset{source: %Customer{}}

  """
  def change_customer(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end

  alias Tq2.Sales.Order

  @doc """
  Returns the list of orders.

  ## Examples

      iex> list_orders(%Account{}, %{})
      [%Order{}, ...]

  """
  def list_orders(account, params) do
    Order
    |> where(account_id: ^account.id)
    |> Repo.paginate(params)
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
    Order
    |> where(account_id: ^account.id)
    |> join(:left, [o], c in assoc(o, :cart))
    |> join(:left, [o, c], l in assoc(c, :lines))
    |> preload([o, c, l], cart: {c, lines: l})
    |> Repo.get!(id)
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

      iex> change_order(%Account{}, order)
      %Ecto.Changeset{source: %Order{}}

  """
  def change_order(%Account{} = account, %Order{} = order) do
    Order.changeset(account, order, %{})
  end
end
