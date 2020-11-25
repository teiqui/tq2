defmodule Tq2.Transactions do
  @moduledoc """
  The Transactions context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Trail
  alias Tq2.Accounts.Account
  alias Tq2.Transactions.Cart

  @doc """
  Gets a single cart.

  Raises `Ecto.NoResultsError` if the Cart does not exist.

  ## Examples

      iex> get_cart!(%Account{}, 123)
      %Cart{}

      iex> get_cart!(%Account{}, 456)
      ** (Ecto.NoResultsError)

  """
  def get_cart!(account, id) do
    Cart
    |> where(account_id: ^account.id)
    |> Repo.get!(id)
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
    account
    |> Cart.changeset(%Cart{}, attrs)
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
    account
    |> Cart.changeset(cart, attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking cart changes.

  ## Examples

      iex> change_cart(%Account{}, cart)
      %Ecto.Changeset{source: %Cart{}}

  """
  def change_cart(%Account{} = account, %Cart{} = cart) do
    Cart.changeset(account, cart, %{})
  end
end
