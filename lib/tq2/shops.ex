defmodule Tq2.Shops do
  @moduledoc """
  The Shops context.
  """

  import Ecto.Query, warn: false

  alias Tq2.{Repo, Trail}
  alias Tq2.Accounts.{Account, Session}
  alias Tq2.Shops.Store

  @doc """
  Gets a single store.

  Raises `Ecto.NoResultsError` if the Store does not exist or if isn't published or has locked license (only when looking for slug).

  ## Examples

      iex> get_store!(%Account{})
      %Store{}

      iex> get_store!("slug")
      %Store{}

      iex> get_store!(%Account{})
      ** (Ecto.NoResultsError)

      iex> get_store!("not_found")
      ** (Ecto.NoResultsError)

  """
  def get_store!(%Account{} = account) do
    store = Repo.get_by!(Store, account_id: account.id)

    %{store | account: account}
  end

  def get_store!(slug) do
    two_weeks_ago = Date.utc_today() |> Timex.shift(weeks: -2)

    Store
    |> join(:inner, [s], a in assoc(s, :account))
    |> join(:inner, [s, a], l in assoc(a, :license))
    |> join(:left, [s, a], u in assoc(a, :owner))
    |> where(
      [s, a, l],
      s.slug == ^slug and s.published == true and
        (l.status != "locked" or l.paid_until >= ^two_weeks_ago)
    )
    |> preload([s, a, l, o], account: {a, owner: o})
    |> Repo.one!()
  end

  @doc """
  Gets a single store.

  Returns nil if the Store does not exist.

  ## Examples

      iex> get_store(%Account{})
      %Store{}

      iex> get_store(%Account{})
      nil

  """
  def get_store(%Account{} = account) do
    Repo.get_by(Store, account_id: account.id)
  end

  @doc """
  Creates a store.

  ## Examples

      iex> create_store(%Session{}, %{field: value})
      {:ok, %Store{}}

      iex> create_store(%Session{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_store(%Session{account: account, user: user}, attrs) do
    account
    |> Store.changeset(%Store{}, attrs)
    |> Trail.insert(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Updates a store.

  ## Examples

      iex> update_store(%Session{}, store, %{field: new_value})
      {:ok, %Store{}}

      iex> update_store(%Session{}, store, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_store(%Session{account: account, user: user}, %Store{} = store, attrs) do
    account
    |> Store.changeset(store, attrs)
    |> Trail.update(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking store changes.

  ## Examples

      iex> change_store(%Account{}, store)
      %Ecto.Changeset{source: %Store{}}

  """
  def change_store(%Account{} = account, %Store{} = store, attrs \\ %{}) do
    Store.changeset(account, store, attrs)
  end
end
