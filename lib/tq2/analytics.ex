defmodule Tq2.Analytics do
  @moduledoc """
  The Analytics context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Accounts.Account
  alias Tq2.Analytics.Visit

  @doc """
  Returns the list of visits.

  ## Examples

      iex> list_visits(%Account{}, %{})
      [%Visit{}, ...]

  """
  def list_visits(account, params) do
    Visit
    |> where(account_id: ^account.id)
    |> Repo.paginate(params)
  end

  @doc """
  Gets a single visit.

  Raises `Ecto.NoResultsError` if the Visit does not exist.

  ## Examples

      iex> get_visit!(%Account{}, 123)
      %Visit{}

      iex> get_visit!(%Account{}, 456)
      ** (Ecto.NoResultsError)

  """
  def get_visit!(account, id) do
    Visit
    |> where(account_id: ^account.id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a visit.

  ## Examples

      iex> create_visit(%Account{}, %{field: value})
      {:ok, %Visit{}}

      iex> create_visit(%Account{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_visit(%Account{} = account, attrs) do
    %Visit{}
    |> Visit.changeset(attrs, account)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking visit changes.

  ## Examples

      iex> change_visit(%Account{}, visit)
      %Ecto.Changeset{source: %Visit{}}

  """
  def change_visit(%Account{} = account, %Visit{} = visit) do
    Visit.changeset(visit, %{}, account)
  end

  alias Tq2.Analytics.View

  @doc """
  Returns the list of views.

  ## Examples

      iex> list_views(%Account{}, %{})
      [%View{}, ...]

  """
  def list_views(account, params) do
    View
    |> join(:inner, [view], visit in assoc(view, :visit))
    |> where([view, visit], visit.account_id == ^account.id)
    |> Repo.paginate(params)
  end

  @doc """
  Gets a single view.

  Raises `Ecto.NoResultsError` if the View does not exist.

  ## Examples

      iex> get_view!(%Account{}, 123)
      %View{}

      iex> get_view!(%Account{}, 456)
      ** (Ecto.NoResultsError)

  """
  def get_view!(account, id) do
    View
    |> join(:inner, [view], visit in assoc(view, :visit))
    |> where([view, visit], visit.account_id == ^account.id)
    |> Repo.get!(id)
  end

  @doc """
  Creates a view.

  ## Examples

      iex> create_view(%Account{}, %{field: value})
      {:ok, %View{}}

      iex> create_view(%Account{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_view(%Account{} = account, attrs) do
    account
    |> View.changeset(%View{}, attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking view changes.

  ## Examples

      iex> change_view(%Account{}, view)
      %Ecto.Changeset{source: %View{}}

  """
  def change_view(%Account{} = account, %View{} = view) do
    View.changeset(account, view, %{})
  end
end
