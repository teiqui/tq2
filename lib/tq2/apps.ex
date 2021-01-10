defmodule Tq2.Apps do
  @moduledoc """
  The Apps context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Trail
  alias Tq2.Accounts.{Account, Session}
  alias Tq2.Apps.{App, MercadoPago, WireTransfer}

  @payment_names ~w(mercado_pago wire_transfer)
  @app_names ~w(mercado_pago wire_transfer)
  @app_modules %{
    "mercado_pago" => MercadoPago,
    "wire_transfer" => WireTransfer
  }

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
  Returns the list of payment apps.

  ## Examples

      iex> payment_apps(%Account{})
      [%App{}, ...]

  """
  def payment_apps(account) do
    App
    |> where(account_id: ^account.id)
    |> where([a], a.name in @payment_names)
    |> Repo.all()
  end

  @doc """
  Returns an app for account

  ## Examples

      iex> get_app(%Account{}, "mercado_pago")
      %MercadoPago{}

  """
  def get_app(account, "mercado_pago") do
    MercadoPago
    |> Repo.get_by(account_id: account.id, name: "mercado_pago")
  end

  def get_app(account, "wire_transfer") do
    WireTransfer
    |> Repo.get_by(account_id: account.id, name: "wire_transfer")
  end

  # @doc """
  # Creates an app.

  # ## Examples

  #     iex> create_app(%Session{}, %{field: "value"})
  #     {:ok, %MercadoPago{}}

  #     iex> create_app(%Session{}, %{field: "bad_value"})
  #     {:error, %Ecto.Changeset{}}

  # """
  def create_app(%Session{account: account, user: user}, %{"name" => app_name} = attrs)
      when app_name in @app_names do
    module = @app_modules[app_name]

    account
    |> module.changeset(module.__struct__, attrs)
    |> Trail.insert(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Updates an app.

  ## Examples

      iex> update_app(%Session{}, app, %{field: "new_value"})
      {:ok, %MercadoPago{}}

      iex> update_app(%Session{}, app, %{field: "bad_value"})
      {:error, %Ecto.Changeset{}}

  """
  def update_app(%Session{account: account, user: user}, %MercadoPago{} = app, attrs) do
    account
    |> MercadoPago.changeset(app, attrs)
    |> Trail.update(originator: user, meta: %{account_id: account.id})
  end

  def update_app(%Session{account: account, user: user}, %WireTransfer{} = app, attrs) do
    account
    |> WireTransfer.changeset(app, attrs)
    |> Trail.update(originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Deletes an app.

  ## Examples

      iex> delete_app(%Session{}, app)
      {:ok, %MercadoPago{}}

      iex> delete_app(%Session{}, app)
      {:error, %Ecto.Changeset{}}

  """
  def delete_app(%Session{account: account, user: user}, app) do
    Trail.delete(app, originator: user, meta: %{account_id: account.id})
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for App changes.

  ## Examples

      iex> change_app(%Account{}, app)
      %Ecto.Changeset{source: %MercadoPago{}}

  """
  def change_app(account, app, attrs \\ %{})

  def change_app(%Account{} = account, %MercadoPago{} = app, attrs) do
    MercadoPago.changeset(account, app, attrs)
  end

  def change_app(%Account{} = account, %WireTransfer{} = app, attrs) do
    WireTransfer.changeset(account, app, attrs)
  end

  @doc """
  Returns a MercadoPago app.

  ## Examples

      iex> get_mercado_pago_by_user_id(123)
      %MercadoPago{}

      iex> get_mercado_pago_by_user_id(321)
      nil
  """
  def get_mercado_pago_by_user_id(user_id) do
    MercadoPago
    |> where(fragment("(data ->> 'user_id' = ?)", ^user_id))
    |> join(:inner, [app], a in assoc(app, :account))
    |> preload([app, a], account: a)
    |> Repo.one()
  end
end
