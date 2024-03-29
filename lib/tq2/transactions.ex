defmodule Tq2.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Tq2.Repo
  alias Tq2.Accounts.Account
  alias Tq2.Transactions.Cart

  @doc """
  Gets abandoned carts.

  ## Examples

      iex> get_carts(%Account{}, %{})
      [%Cart{}, ...]

  """
  def get_carts(%Account{} = account, params) do
    tolerance = Timex.now() |> Timex.shift(minutes: -15)

    Cart
    |> where(account_id: ^account.id)
    |> join(:inner, [c], l in assoc(c, :lines))
    |> join(:left, [c], o in assoc(c, :order))
    |> join(:inner, [c], customer in assoc(c, :customer))
    |> where([c, l, o], is_nil(o.id) and c.updated_at < ^tolerance)
    |> order_by([c], desc: c.updated_at)
    |> preload([c, l, o, customer], customer: customer, lines: l)
    |> Repo.paginate(params)
  end

  @doc """
  Gets a single cart.

  ## Examples

      iex> get_cart(%Account{}, "token")
      %Cart{}

      iex> get_cart(%Account{}, "invalid_token")
      nil

  """
  def get_cart(%Account{} = account, token) do
    Cart
    |> where(account_id: ^account.id, token: ^token)
    |> join(:left, [c], l in assoc(c, :lines))
    |> join(:left, [c], o in assoc(c, :order))
    |> join(:left, [c], customer in assoc(c, :customer))
    |> where([c, l, o], is_nil(o.id))
    |> preload([c, l, o, customer], customer: customer, lines: l)
    |> Repo.one()
    |> maybe_add_account(account)
  end

  @doc """
  Gets a cart with all its info.

  Raises `Ecto.NoResultsError` if the Cart does not exist.

  ## Examples

      iex> get_cart!(%Account{}, 1)
      %Cart{}

      iex> get_cart!(%Account{}, 0)
      ** (Ecto.NoResultsError)

  """
  def get_cart!(%Account{} = account, id) do
    Cart
    |> where(account_id: ^account.id, id: ^id)
    |> join(:left, [c], l in assoc(c, :lines))
    |> join(:left, [c], o in assoc(c, :order))
    |> join(:left, [c], customer in assoc(c, :customer))
    |> join(:left, [c], p in assoc(c, :payments))
    |> join(:left, [c, l], i in assoc(l, :item))
    |> preload(
      [c, l, o, customer, p, i],
      customer: customer,
      lines: {l, item: i},
      order: o,
      payments: p
    )
    |> Repo.one!()
  end

  @doc """
  Creates a cart.

  ## Examples

      iex> create_cart(%Account{}, %{field: value})
      {:ok, %Cart{}}

      iex> create_cart(%Account{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_cart(%Account{} = account, attrs) do
    %Cart{}
    |> Cart.changeset(attrs, account)
    |> Repo.insert()
  end

  @doc """
  Updates a cart.

  ## Examples

      iex> update_cart(%Account{}, cart, %{field: new_value})
      {:ok, %Cart{}}

      iex> update_cart(%Account{}, cart, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_cart(%Account{} = account, %Cart{} = cart, attrs) do
    cart
    |> Cart.changeset(attrs, account)
    |> Repo.update()
    |> notify(attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cart changes.

  ## Examples

      iex> change_cart(%Account{}, cart)
      %Ecto.Changeset{source: %Cart{}}

  """
  def change_cart(%Account{} = account, %Cart{} = cart, attrs \\ %{}) do
    Cart.changeset(cart, attrs, account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cart changes for handing.

  ## Examples

      iex> change_handing_cart(%Account{}, cart)
      %Ecto.Changeset{source: %Cart{}}

  """
  def change_handing_cart(%Account{} = account, %Cart{} = cart, attrs \\ %{}) do
    Cart.handing_changeset(cart, attrs, account)
  end

  @doc """
  Returns true if data from other cart can be copied to the first one.

  ## Examples

      iex> can_be_copied?(%Store{}, cart, other)
      true

      iex> can_be_copied?(%Store{}, cart, other)
      false

  """
  defdelegate can_be_copied?(store, cart, other), to: Cart

  @doc """
  Copy cart data and customer from one cart to another. If it succeeds, returns
  data with copied = true, and false otherwise

  ## Examples

      iex> fill_cart(%Store{}, cart, other)
      %Cart{data: %{copied: true}}

      iex> fill_cart(%Store{}, cart, other)
      %Cart{data: %{copied: false}}

  """
  def fill_cart(store, cart, previuos_cart) do
    data = Cart.extract_data(store, cart, previuos_cart)
    attrs = %{customer_id: previuos_cart.customer_id, data: data}

    case update_cart(store.account, cart, attrs) do
      {:ok, cart} ->
        %{cart | customer: previuos_cart.customer}

      {:error, _changeset} ->
        cart
    end
  end

  alias Tq2.Transactions.Line

  @doc """
  Gets a single line.

  Raises `Ecto.NoResultsError` if the Line does not exist.

  ## Examples

      iex> get_line!(%Cart{}, 123)
      %Line{}

      iex> get_line!(%Cart{}, 456)
      ** (Ecto.NoResultsError)

  """
  def get_line!(cart, id) do
    Line
    |> where(cart_id: ^cart.id)
    |> join(:left, [l], i in assoc(l, :item))
    |> preload([l, i], item: i)
    |> Repo.get!(id)
  end

  @doc """
  Creates a line.

  ## Examples

      iex> create_line(%Cart{}, %{field: value})
      {:ok, %Line{}}

      iex> create_line(%Cart{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_line(%Cart{} = cart, %{item: item} = attrs) do
    cart
    |> Line.changeset(%Line{item: item}, attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a line.

  ## Examples

      iex> update_line(%Cart{}, line, %{field: new_value})
      {:ok, %Line{}}

      iex> update_line(%Cart{}, line, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_line(%Cart{} = cart, %Line{} = line, attrs) do
    cart
    |> Line.changeset(line, attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Line.

  ## Examples

      iex> delete_line(line)
      {:ok, %Line{}}

      iex> delete_line(line)
      {:error, %Ecto.Changeset{}}

  """
  def delete_line(%Line{} = line) do
    Repo.delete(line)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking line changes.

  ## Examples

      iex> change_line(%Cart{}, line)
      %Ecto.Changeset{source: %Line{}}

  """
  def change_line(%Cart{} = cart, %Line{} = line, attrs \\ %{}) do
    Line.changeset(cart, line, attrs)
  end

  @doc """
  Copy lines from one cart to another.

  ## Examples

      iex> copy_lines(%Cart{} = from, %Cart{} = to)
      {:ok, %Ecto.Changeset{}}

      iex> copy_lines(%Cart{line: %{item: nil}}, %Cart{})
      {:error, "add_xx", %Ecto.Changeset{}, changes}

  """
  def copy_lines(%Cart{} = from_cart, %Cart{} = cart) do
    Multi.new()
    |> multi_change_cart(cart)
    |> multi_remove_lines(cart.lines)
    |> multi_add_lines(cart, from_cart.lines)
    |> Repo.transaction()
  end

  defp multi_change_cart(multi, %{price_type: "promotional"}), do: multi

  defp multi_change_cart(multi, cart) do
    changeset = cart.account |> change_cart(cart, %{price_type: "promotional"})

    multi |> Multi.update(:cart, changeset)
  end

  defp multi_remove_lines(multi, lines) do
    lines
    |> Enum.reduce(multi, fn line, memo ->
      memo |> Multi.delete("rm_#{line.id}", line)
    end)
  end

  defp multi_add_lines(multi, cart, lines) do
    lines
    |> Enum.reduce(multi, fn line, memo ->
      attrs = %{line | cart_id: nil, cart: cart} |> Map.from_struct()
      changeset = cart |> change_line(%Line{item: line.item}, attrs)

      memo |> Multi.insert("add_#{line.id}", changeset)
    end)
  end

  # Notify owner after updated cart with customer
  defp notify(
         {:ok, %{customer_id: customer_id} = cart} = result,
         %{customer_id: _}
       )
       when is_integer(customer_id) do
    exec_at = Timex.now() |> Timex.shift(minutes: 15)

    Exq.enqueue_at(Exq, "default", exec_at, Tq2.Workers.NotificationsJob, [
      "notify_abandoned_cart_to_user",
      cart.account_id,
      cart.token
    ])

    result
  end

  # Notify customer with abandoned cart reminder
  defp notify(
         {:ok, %{customer_id: customer_id} = cart} = result,
         %{data: %{notified_at: %DateTime{}}}
       )
       when is_integer(customer_id) do
    Exq.enqueue(Exq, "default", Tq2.Workers.NotificationsJob, [
      "notify_abandoned_cart_to_customer",
      cart.account_id,
      cart.token
    ])

    result
  end

  defp notify(result, _attrs), do: result

  defp maybe_add_account(nil, _account), do: nil
  defp maybe_add_account(record, account), do: %{record | account: account}
end
