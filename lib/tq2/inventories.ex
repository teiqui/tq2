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

      iex> list_categories(%Account{})
      [%Category{}, ...]

  """
  def list_categories(account) do
    account
    |> list_categories_query()
    |> Repo.all()
  end

  @doc """
  Returns the list of categories.

  ## Examples

      iex> list_categories(%Account{}, %{})
      [%Category{}, ...]

  """
  def list_categories(account, params) do
    account
    |> list_categories_query()
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

  defp list_categories_query(account) do
    Category
    |> where(account_id: ^account.id)
    |> order_by(asc: :name)
  end

  alias Tq2.Inventories.Item

  @doc """
  Returns the list of items.

  ## Examples

      iex> list_items(%Account{}, %{})
      [%Item{}, ...]

  """
  def list_items(account, params) do
    account
    |> list_items_query()
    |> Repo.paginate(params)
  end

  @doc """
  Returns the list of visible items.

  ## Examples

      iex> list_visible_items(%Account{}, %{})
      [%Item{}, ...]

  """
  def list_visible_items(account, params) do
    account
    |> list_items_query()
    |> where(visibility: "visible")
    |> Repo.paginate(params)
  end

  @doc """
  Gets a single item.

  Raises `Ecto.NoResultsError` if the Item does not exist.

  ## Examples

      iex> get_item!(%Account{}, 123)
      %Item{}

      iex> get_item!(%Account{}, 456)
      ** (Ecto.NoResultsError)

  """
  def get_item!(account, id) do
    Item
    |> where(account_id: ^account.id)
    |> join(:left, [i], c in assoc(i, :category))
    |> preload([i, c], category: c)
    |> Repo.get!(id)
  end

  @doc """
  Creates a item.

  ## Examples

      iex> create_item(%Session{}, %{field: value})
      {:ok, %Item{}}

      iex> create_item(%Session{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_item(%Session{account: account, user: user}, attrs) do
    account
    |> Item.changeset(%Item{}, attrs)
    |> Trail.insert(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(%Session{}, item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(%Session{}, item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Session{account: account, user: user}, %Item{} = item, attrs) do
    account
    |> Item.changeset(item, attrs)
    |> Trail.update(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Deletes a Item.

  ## Examples

      iex> delete_item(%Session{}, item)
      {:ok, %Item{}}

      iex> delete_item(%Session{}, item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Session{account: account, user: user}, %Item{image: nil} = item) do
    Trail.delete(item, originator: user, meta: %{account_id: account.id})
  end

  def delete_item(%Session{} = session, %Item{image: image} = item) do
    :ok = Tq2.ImageUploader.delete({image, item})

    delete_item(session, %{item | image: nil})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking item changes.

  ## Examples

      iex> change_item(%Account{}, item)
      %Ecto.Changeset{source: %Item{}}

  """
  def change_item(%Account{} = account, %Item{} = item) do
    Item.changeset(account, item, %{})
  end

  defp list_items_query(account) do
    Item
    |> where(account_id: ^account.id)
    |> join(:left, [i], c in assoc(i, :category))
    |> order_by(asc: :name)
    |> preload([i, c], category: c)
  end
end
