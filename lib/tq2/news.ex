defmodule Tq2.News do
  @moduledoc """
  The News context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Trail
  alias Tq2.Accounts.Session
  alias Tq2.News.Note

  @doc """
  Returns the list of notes.

  ## Examples

      iex> list_notes(%{})
      [%Note{}, ...]

  """
  def list_notes(params) do
    Note |> Repo.paginate(params)
  end

  @doc """
  Gets a single note.

  Raises `Ecto.NoResultsError` if the Note does not exist.

  ## Examples

      iex> get_note!(123)
      %Note{}

      iex> get_note!(456)
      ** (Ecto.NoResultsError)

  """
  def get_note!(id) do
    Note |> Repo.get!(id)
  end

  @doc """
  Creates a note.

  ## Examples

      iex> create_note(%Session{}, %{field: value})
      {:ok, %Note{}}

      iex> create_note(%Session{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_note(%Session{user: user}, attrs) do
    %Note{}
    |> Note.changeset(attrs)
    |> Trail.insert(originator: user)
    |> notify()
  end

  @doc """
  Updates a note.

  ## Examples

      iex> update_note(%Session{}, note, %{field: new_value})
      {:ok, %Note{}}

      iex> update_note(%Session{}, note, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_note(%Session{user: user}, %Note{} = note, attrs) do
    note
    |> Note.changeset(attrs)
    |> Trail.update(originator: user)
  end

  @doc """
  Deletes a Note.

  ## Examples

      iex> delete_note(%Session{}, note)
      {:ok, %Note{}}

      iex> delete_note(%Session{}, note)
      {:error, %Ecto.Changeset{}}

  """
  def delete_note(%Session{user: user}, %Note{} = note) do
    Trail.delete(note, originator: user)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking note changes.

  ## Examples

      iex> change_note(note)
      %Ecto.Changeset{source: %Note{}}

  """
  def change_note(%Note{} = note) do
    Note.changeset(note, %{})
  end

  defp notify({:ok, %{id: id}} = result) do
    Exq.enqueue(Exq, "default", Tq2.Workers.NotificationsJob, ["new_note", id])

    result
  end

  defp notify({:error, _} = result), do: result
end
