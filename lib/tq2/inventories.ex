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
  Subscribe to be notified about changes on items and categories.

  ## Examples

      iex> subscribe(%Session{})
      :ok

  """
  def subscribe(%Session{account: account, user: user}) do
    Phoenix.PubSub.subscribe(Tq2.PubSub, "inventories:#{account.id}:#{user.id}")
  end

  @doc """
  Broadcast the given message.

  ## Examples

      iex> broadcast({:ok, "some result"}, %Session{}, :event_finished)
      {:ok, "some result"}

  """
  def broadcast(result, %Session{account: account, user: user}, message) do
    Phoenix.PubSub.broadcast(
      Tq2.PubSub,
      "inventories:#{account.id}:#{user.id}",
      {message, result}
    )

    result
  end

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
  Returns the list of categories ordering items with images first.

  ## Examples

      iex> categories_with_images(%Account{})
      [%Category{}, ...]

  """

  def categories_with_images(account) do
    account
    |> preload_items_per_category()
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
  def create_category(%Session{account: account, user: user} = session, attrs) do
    account
    |> Category.changeset(%Category{}, attrs)
    |> Trail.insert(originator: user, meta: %{account_id: account.id})
    |> broadcast(session, :create_category_finished)
  end

  @doc """
  Updates a category.

  ## Examples

      iex> update_category(%Session{}, category, %{field: new_value})
      {:ok, %Category{}}

      iex> update_category(%Session{}, category, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_category(
        %Session{account: account, user: user} = session,
        %Category{} = category,
        attrs
      ) do
    account
    |> Category.changeset(category, attrs)
    |> Trail.update(originator: user, meta: %{account_id: account.id})
    |> broadcast(session, :update_category_finished)
  end

  @doc """
  Deletes a Category.

  ## Examples

      iex> delete_category(%Session{}, category)
      {:ok, %Category{}}

      iex> delete_category(%Session{}, category)
      {:error, %Ecto.Changeset{}}

  """
  def delete_category(%Session{account: account, user: user} = session, %Category{} = category) do
    category
    |> Trail.delete(originator: user, meta: %{account_id: account.id})
    |> broadcast(session, :delete_category_finished)
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

  @doc """
  Get or create a category per name

  ## Examples

      iex> get_or_create_category_by_name(%Session{}, %{name: new_value})
      {:ok, %Item{}}

      iex> get_or_create_category_by_name(%Session{}, %{name: bad_name})
      {:error, %Ecto.Changeset{}}

  """
  def get_or_create_category_by_name(%Session{account: account} = session, %{name: name} = attrs) do
    Category
    |> where(account_id: ^account.id)
    |> where([c], ilike(c.name, ^String.trim(name)))
    |> Repo.one()
    |> get_or_create_category(session, attrs)
  end

  defp get_or_create_category(nil, session, attrs), do: create_category(session, attrs)

  defp get_or_create_category(category, _, _), do: {:ok, category}

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
    params = Map.put(params, :visibility, "all")

    account
    |> list_items_query()
    |> filter_items_by_params(params)
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
    |> filter_items_by_params(params)
    |> Repo.paginate(params)
  end

  @doc """
  Returns the number of items.

  ## Examples

      iex> items_count(%Account{})
      10

  """
  def items_count(account) do
    Item
    |> where(account_id: ^account.id)
    |> select([i], count(i.id))
    |> Repo.one!()
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
  def create_item(%Session{account: account, user: user} = session, attrs) do
    account
    |> Item.changeset(%Item{}, attrs)
    |> Trail.insert(originator: user, meta: %{account_id: account.id})
    |> broadcast(session, :create_item_finished)
  end

  @doc """
  Updates a item.

  ## Examples

      iex> update_item(%Session{}, item, %{field: new_value})
      {:ok, %Item{}}

      iex> update_item(%Session{}, item, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_item(%Session{account: account, user: user} = session, %Item{} = item, attrs) do
    account
    |> Item.changeset(item, attrs)
    |> Trail.update(originator: user, meta: %{account_id: account.id})
    |> broadcast(session, :update_item_finished)
  end

  @doc """
  Deletes a Item.

  ## Examples

      iex> delete_item(%Session{}, item)
      {:ok, %Item{}}

      iex> delete_item(%Session{}, item)
      {:error, %Ecto.Changeset{}}

  """
  def delete_item(%Session{account: account, user: user} = session, %Item{image: nil} = item) do
    item
    |> Trail.delete(originator: user, meta: %{account_id: account.id})
    |> broadcast(session, :delete_item_finished)
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
  def change_item(%Account{} = account, %Item{} = item, attrs \\ %{}) do
    Item.changeset(account, item, attrs)
  end

  @doc """
  Create or update an item per name

  ## Examples

      iex> create_or_update_item(%Session{}, %{name: new_value})
      {:ok, %Item{}}

      iex> create_or_update_item(%Session{}, %{name: bad_name})
      {:error, %Ecto.Changeset{}}

  """
  def create_or_update_item(%Session{account: account} = session, %{name: name} = attrs) do
    Item
    |> where(account_id: ^account.id)
    |> where([i], ilike(i.name, ^String.trim(name)))
    |> Repo.one()
    |> create_or_update_item(session, attrs)
  end

  defp create_or_update_item(nil, session, attrs) do
    session |> create_item(attrs)
  end

  defp create_or_update_item(%Item{} = item, session, attrs) do
    session |> update_item(item, attrs)
  end

  defp list_items_query(account) do
    Item
    |> where(account_id: ^account.id)
    |> join(:left, [i], c in assoc(i, :category))
    |> order_by(asc: :name)
    |> preload([i, c], category: c)
  end

  defp preload_items_per_category(account, count \\ 4) do
    from c in Category,
      as: :category,
      where: [account_id: ^account.id],
      join: i in assoc(c, :items),
      inner_lateral_join:
        sub in subquery(
          from item in Item,
            where:
              item.category_id == parent_as(:category).id and
                item.visibility == "visible",
            limit: ^count,
            order_by: [asc: :image],
            select: [:id]
        ),
      on: sub.id == i.id,
      preload: [items: i]
  end

  defp search_items(item_scope, query) do
    case String.trim(query) do
      "" ->
        item_scope

      query ->
        where(
          item_scope,
          [i],
          fragment(
            """
              (
                (immutable_unaccent(?) % ANY(STRING_TO_ARRAY(immutable_unaccent(?), ' '))) OR
                (immutable_unaccent(?) %>> ANY(STRING_TO_ARRAY(immutable_unaccent(?), ' ')))
              )
            """,
            i.name,
            ^query,
            i.name,
            ^query
          )
        )
    end
  end

  defp filter_items_by_params(items_scope, %{search: query} = params) when is_binary(query) do
    items_scope
    |> search_items(query)
    |> filter_items_by_params(Map.delete(params, :search))
  end

  defp filter_items_by_params(items_scope, %{category_id: id} = params) when is_number(id) do
    items_scope
    |> where(category_id: ^id)
    |> filter_items_by_params(Map.delete(params, :category_id))
  end

  defp filter_items_by_params(items_scope, %{visibility: "all"}) do
    items_scope
  end

  defp filter_items_by_params(items_scope, _params) do
    items_scope |> where(visibility: "visible")
  end
end
