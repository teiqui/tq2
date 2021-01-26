defmodule Tq2.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Accounts.Account
  alias Tq2.Transactions.Cart

  @doc """
  Gets a single cart.

  Raises `Ecto.NoResultsError` if the Cart does not exist.

  ## Examples

      iex> get_cart(%Account{}, "token")
      %Cart{}

      iex> get_cart(%Account{}, "invalid_token")
      nil

  """
  def get_cart(account, token) do
    Cart
    |> where(account_id: ^account.id, token: ^token)
    |> join(:left, [c], l in assoc(c, :lines))
    |> join(:left, [c], o in assoc(c, :order))
    |> where([c, l, o], is_nil(o.id))
    |> preload([c, l], lines: l)
    |> Repo.one()
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
  def change_line(%Cart{} = cart, %Line{} = line) do
    Line.changeset(cart, line, %{})
  end
end
