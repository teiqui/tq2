defmodule Tq2.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Trail
  alias Tq2.Accounts.Account
  alias Tq2.Payments.LicensePayment, as: LPayment

  @doc """
  Returns the list of license_payments.

  ## Examples

      iex> list_recent_license_payments(%Account{})
      [%LPayment{}, ...]

  """
  def list_recent_license_payments(account) do
    LPayment
    |> where(account_id: ^account.id)
    |> order_by(desc: :inserted_at)
    |> limit(5)
    |> Repo.all()
  end

  @doc """
  Creates or Updates a license payment.

  ## Examples

      iex> create_or_update_license_payment(%{field: new_value}, %Account{})
      {:ok, %LPayment{}}

      iex> create_or_update_license_payment(%{field: bad_value}, %Account{})
      nil

  """
  def create_or_update_license_payment(%{external_id: external_id} = attrs, %Account{} = account)
      when is_binary(external_id) do
    LPayment
    |> where(account_id: ^account.id, external_id: ^external_id)
    |> Repo.one()
    |> process_license_payment(account, attrs)
  end

  def create_or_update_license_payment(_attrs, %Account{} = _account), do: nil

  defp process_license_payment(nil, %Account{} = account, attrs) do
    account
    |> LPayment.changeset(%LPayment{}, attrs)
    |> Trail.insert(meta: %{account_id: account.id})
  end

  defp process_license_payment(payment, %Account{} = account, attrs) do
    account
    |> LPayment.changeset(payment, attrs)
    |> Trail.update(meta: %{account_id: account.id})
  end
end
