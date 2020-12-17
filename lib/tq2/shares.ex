defmodule Tq2.Shares do
  @moduledoc """
  The Shares context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Shares.Token

  @doc """
  Gets a single token.

  Raises `Ecto.NoResultsError` if the Token does not exist.

  ## Examples

      iex> get_token!(%Account{}, "token")
      %Token{}

      iex> get_token!(%Account{}, "invalid_token")
      ** (Ecto.NoResultsError)

  """
  def get_token!(token) do
    Repo.get_by!(Token, value: token)
  end

  @doc """
  Creates a token.

  ## Examples

      iex> create_token(%{field: value})
      {:ok, %Token{}}

      iex> create_token(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_token(attrs) do
    %Token{}
    |> Token.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a token.

  ## Examples

      iex> update_token(token, %{field: new_value})
      {:ok, %Token{}}

      iex> update_token(token, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_token(%Token{} = token, attrs) do
    token
    |> Token.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a Token.

  ## Examples

      iex> delete_token(token)
      {:ok, %Token{}}

      iex> delete_token(token)
      {:error, %Ecto.Changeset{}}

  """
  def delete_token(%Token{} = token) do
    Repo.delete(token)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking token changes.

  ## Examples

      iex> change_token(token)
      %Ecto.Changeset{source: %Token{}}

  """
  def change_token(%Token{} = token) do
    Token.changeset(token, %{})
  end
end
