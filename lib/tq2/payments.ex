defmodule Tq2.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Accounts.{Account, License}
  alias Tq2.Payments.LicensePayment, as: LPayment
  alias Tq2.Payments.Payment
  alias Tq2.Repo
  alias Tq2.Trail
  alias Tq2.Transactions.Cart

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

  def create_or_update_license_payment(_attrs, %Account{}), do: nil

  @doc """
  Creates a payment.

  ## Examples

      iex> create_payment(%Cart{}, %{field: value})
      {:ok, %Payment{}}

      iex> create_payment(%Cart{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_payment(%Cart{} = cart, attrs) do
    cart
    |> Payment.changeset(%Payment{}, attrs)
    |> Trail.insert(meta: %{account_id: cart.account_id})
  end

  @doc """
  Updates a payment.

  ## Examples

      iex> update_payment(%{field: "new_value"}, %Account{})
      {:ok, %Payment{}}

      iex> update_payment(%{field: "bad_value"}, %Account{})
      nil

  """
  def update_payment(%{external_id: external_id}, %Account{})
      when is_binary(external_id) do
    "TBD"
  end

  def update_payment(_attrs, %Account{}), do: nil

  defp process_license_payment(nil, %Account{} = account, attrs) do
    account
    |> LPayment.changeset(%LPayment{}, attrs)
    |> insert_with_license(account)
  end

  defp process_license_payment(payment, %Account{} = account, attrs) do
    account
    |> LPayment.changeset(payment, attrs)
    |> update_with_license(account)
  end

  defp insert_with_license(%Ecto.Changeset{valid?: false} = changeset, _account),
    do: {:error, changeset}

  defp insert_with_license(%Ecto.Changeset{} = changeset, %Account{} = account) do
    Ecto.Multi.new()
    |> PaperTrail.Multi.insert(changeset, meta: %{account_id: account.id})
    |> update_license_with_payment(account)
  end

  defp update_with_license(%Ecto.Changeset{valid?: false} = changeset, _),
    do: {:error, changeset}

  defp update_with_license(%Ecto.Changeset{} = changeset, %Account{} = account) do
    empty_map = %{}

    case changeset.changes do
      ^empty_map ->
        # skip version without changes
        {:ok, changeset.data}

      _ ->
        Ecto.Multi.new()
        |> PaperTrail.Multi.update(changeset, meta: %{account_id: account.id})
        |> update_license_with_payment(account)
    end
  end

  defp update_license_with_payment(%Ecto.Multi{} = multi, %Account{} = account) do
    account = Repo.preload(account, :license)
    {_, payment_cs, _} = multi.operations[:model]

    account.license
    |> License.put_paid_until_changes(payment_cs)
    |> License.add_changeset_to_multi(multi)
    |> commit_license_and_payment_transaction()
  end

  defp commit_license_and_payment_transaction(multi) do
    case Tq2.Repo.transaction(multi) do
      {:ok, %{model: payment, license: license}} -> {:ok, %{payment | license: license}}
      {:error, _operation, failed_value, _changes} -> {:error, failed_value}
    end
  end
end
