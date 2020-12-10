defmodule Tq2.Apps do
  @moduledoc """
  The Apps context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Trail
  alias Tq2.Accounts.{Account, Session}
  alias Tq2.Apps.{App, MercadoPago}

  @doc """
  Returns the list of apps.

  ## Examples

      iex> list_apps(%Account{})
      [%App{}, ...]

  """
  def list_apps(account) do
    App
    |> where(account_id: ^account.id)
    |> Repo.all()
  end

  @doc """
  Returns the MercadoPago app for account

  ## Examples

      iex> get_app(%Account{}, "mercado_pago")
      %MercadoPago{}

  """
  def get_app(account, "mercado_pago") do
    MercadoPago
    |> where(account_id: ^account.id, name: "mercado_pago")
    |> Repo.one()
  end

  # @doc """
  # Creates a MercadoPago app.

  # ## Examples

  #     iex> create_app(%Session{}, %{field: value})
  #     {:ok, %MercadoPago{}}

  #     iex> create_app(%Session{}, %{field: bad_value})
  #     {:error, %Ecto.Changeset{}}

  # """
  def create_app(%Session{account: account, user: user}, %{name: "mercado_pago"} = attrs) do
    account
    |> MercadoPago.changeset(%MercadoPago{}, attrs)
    |> Trail.insert(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Updates a MercadoPago app.

  ## Examples

      iex> update_app(%Session{}, app, %{field: new_value})
      {:ok, %MercadoPago{}}

      iex> update_app(%Session{}, app, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_app(%Session{account: account, user: user}, %MercadoPago{} = app, attrs) do
    account
    |> MercadoPago.changeset(app, attrs)
    |> Trail.update(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Deletes a MercadoPago.

  ## Examples

      iex> delete_app(%Session{}, app)
      {:ok, %MercadoPago{}}

      iex> delete_app(%Session{}, app)
      {:error, %Ecto.Changeset{}}

  """
  def delete_app(%Session{account: account, user: user}, %MercadoPago{} = app) do
    Trail.delete(app, originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for App changes.

  ## Examples

      iex> change_app(%Account{}, app)
      %Ecto.Changeset{source: %MercadoPago{}}

  """
  def change_app(%Account{} = account, %MercadoPago{} = app, attrs \\ %{}) do
    MercadoPago.changeset(account, app, attrs)
  end
end
