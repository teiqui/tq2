defmodule Tq2.Inventories do
  @moduledoc """
  The Inventories context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Trail
  alias Tq2.Accounts.{Account, Session}
  alias Tq2.Inventories.Category

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories(%Account{}, %{})
      [%Category{}, ...]

  """
  def list_categories(account, params) do
    Category
    |> where(account_id: ^account.id)
    |> order_by(asc: :name)
    |> Repo.paginate(params)
  end

  @doc """
  Gets a single category.

  Raises `Ecto.NoResultsError` if the Category does not exist.

  ## Examples

      iex> get_category!(%Account{}, 123)
      %Category{}

      iex> get_category!(%Account{}, 456)
      ** (Ecto.NoResultsError)

  """
  def get_category!(account, id) do
    Category
    |> where(account_id: ^account.id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a category.

  ## Examples

      iex> create_category(%Session{}, %{field: value})
      {:ok, %Category{}}

      iex> create_category(%Session{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_category(%Session{account: account, user: user}, attrs) do
    account
    |> Category.changeset(%Category{}, attrs)
    |> Trail.insert(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(%Session{}, category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(%Session{}, category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(%Session{account: account, user: user}, %Category{} = category, attrs) do
    account
    |> Category.changeset(category, attrs)
    |> Trail.update(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Deletes a Category.

  ## Examples

      iex> delete_category(%Session{}, category)
      {:ok, %Category{}}

      iex> delete_category(%Session{}, category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Session{account: account, user: user}, %Category{} = category) do
    Trail.delete(category, originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking category changes.

  ## Examples

      iex> change_category(%Account{}, category)
      %Ecto.Changeset{source: %Category{}}

  """
  def change_category(%Account{} = account, %Category{} = category) do
    Category.changeset(account, category, %{})
  end
end
