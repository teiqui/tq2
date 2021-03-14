defmodule Tq2.Messages do
  @moduledoc """
  The Messages context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Messages.Comment
  alias Tq2.Notifications
  alias Tq2.Repo

  @doc """
  Returns the list of comments.

  ## Examples

      iex> list_comments(%Order{})
      [%Comment{}, ...]

  """
  def list_comments(order_id) do
    Comment
    |> where(order_id: ^order_id)
    |> order_by(asc: :inserted_at)
    |> Repo.all()
  end

  @doc """
  Gets a single comment by id.

  Raises `Ecto.NoResultsError` if the Comment does not exist.

  ## Examples

      iex> get_comment!(123)
      %Comment{}

      iex> get_comment!(456)
      ** (Ecto.NoResultsError)

  """
  def get_comment!(id) do
    Repo.get!(Comment, id)
  end

  @doc """
  Creates a comment.

  ## Examples

      iex> create_comment(%{field: value})
      {:ok, %Comment{}}

      iex> create_comment(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_comment(attrs) do
    %Comment{}
    |> Comment.changeset(attrs)
    |> Repo.insert()
    |> notify()
  end

  @doc """
  Updates a comment.

  ## Examples

      iex> update_comment(%Comment{}, %{field: value})
      {:ok, %Comment{}}

      iex> update_comment(%Comment{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_comment(comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking comment changes.

  ## Examples

      iex> change_comment(comment)
      %Ecto.Changeset{source: %Comment{}}

  """
  def change_comment(%Comment{} = comment) do
    Comment.changeset(comment, %{})
  end

  defp notify({:ok, comment}) do
    comment
    |> Repo.preload(:order)
    |> Repo.preload(:customer)
    |> Notifications.notify_new_comment()
  end

  defp notify({:error, _changeset} = result), do: result
end
