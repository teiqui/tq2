defmodule Tq2.Analytics do
  @moduledoc """
  The Analytics context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Analytics.Visit

  @doc """
  Returns the list of visits.

  ## Examples

      iex> list_visits(%{})
      [%Visit{}, ...]

  """
  def list_visits(params) do
    Repo.paginate(Visit, params)
  end

  @doc """
  Gets a single visit by ID or cart_id.

  Raises `Ecto.NoResultsError` if the Visit does not exist.

  ## Examples

      iex> get_visit!(123)
      %Visit{}

      iex> get_visit!(cart_id: 123)
      %Visit{}

      iex> get_visit!(456)
      ** (Ecto.NoResultsError)

  """
  def get_visit!(id) when is_integer(id) do
    Visit
    |> join(:left, [v], r in assoc(v, :referral_customer))
    |> preload([v, r], referral_customer: r)
    |> Repo.get!(id)
  end

  def get_visit!(cart_id: cart_id) do
    Visit
    |> join(:inner, [v], c in assoc(v, :cart))
    |> where([v, c], c.id == ^cart_id)
    |> Repo.one!()
  end

  @doc """
  Creates a visit.

  ## Examples

      iex> create_visit(%{field: value})
      {:ok, %Visit{}}

      iex> create_visit(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_visit(attrs) do
    %Visit{}
    |> Visit.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking visit changes.

  ## Examples

      iex> change_visit(visit)
      %Ecto.Changeset{source: %Visit{}}

  """
  def change_visit(%Visit{} = visit) do
    Visit.changeset(visit, %{})
  end

  alias Tq2.Analytics.View

  @doc """
  Returns the list of views.

  ## Examples

      iex> list_views(%{})
      [%View{}, ...]

  """
  def list_views(params) do
    View
    |> Repo.paginate(params)
  end

  @doc """
  Gets a single view.

  Raises `Ecto.NoResultsError` if the View does not exist.

  ## Examples

      iex> get_view!(123)
      %View{}

      iex> get_view!(456)
      ** (Ecto.NoResultsError)

  """
  def get_view!(id) do
    View
    |> Repo.get!(id)
  end

  @doc """
  Creates a view.

  ## Examples

      iex> create_view(%{field: value})
      {:ok, %View{}}

      iex> create_view(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_view(attrs) do
    %View{}
    |> View.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking view changes.

  ## Examples

      iex> change_view(view)
      %Ecto.Changeset{source: %View{}}

  """
  def change_view(%View{} = view) do
    View.changeset(view, %{})
  end
end
