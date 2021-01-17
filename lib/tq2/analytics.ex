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
  Returns the amount of visits for the slug on the given period and the previous one.

  ## Examples

      iex> visit_counts("example", :daily)
      {current_count, previous_count} = {30, 25}

  """
  def visit_counts(slug, period \\ :daily) do
    {from, to} = range_for(period)
    {previous_from, previous_to} = previous_range_for(period)

    previous_visits =
      Visit
      |> where(
        [v],
        v.slug == ^slug and v.inserted_at >= ^previous_from and v.inserted_at <= ^previous_to
      )
      |> select([v], count(v.id))

    Visit
    |> where([v], v.slug == ^slug and v.inserted_at >= ^from and v.inserted_at <= ^to)
    |> select([v], count(v.id))
    |> union_all(^previous_visits)
    |> Repo.all()
    |> List.to_tuple()
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
    |> join(:left, [v], c in assoc(v, :customer))
    |> join(:left, [v, c], s in assoc(v, :source_token))
    |> join(:left, [v, c, s], r in Tq2.Sales.Customer,
      on: s.customer_id == r.id and (is_nil(c.id) or r.id != c.id)
    )
    |> preload([v, c, s, r], customer: c, referral_customer: r)
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

  defp range_for(:daily) do
    now = DateTime.utc_now()

    {Timex.beginning_of_day(now), Timex.end_of_day(now)}
  end

  defp previous_range_for(:daily) do
    yesterday = DateTime.utc_now() |> Timex.shift(days: -1)

    {Timex.beginning_of_day(yesterday), Timex.end_of_day(yesterday)}
  end
end
