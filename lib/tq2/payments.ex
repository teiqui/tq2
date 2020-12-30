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
  alias Tq2.Sales
  alias Tq2.Sales.Order
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
  Get a payment

  ## Examples

      iex> get_payment!(%Account{}, "123")
      %Payment{}

      iex> get_payment!(%Account{}, "321")
      ** (Ecto.NoResultsError)

  """
  def get_payment!(%Account{} = account, external_id) do
    Payment
    |> join(:left, [p], c in assoc(p, :cart))
    |> where([p, c], c.account_id == ^account.id)
    |> join(:left, [p, c], o in assoc(c, :order))
    |> preload([p, c, o], cart: {c, order: o}, order: o)
    |> Repo.get_by!(external_id: external_id)
    |> Map.put(:account, account)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking payment changes.

  ## Examples

      iex> change_payment(%Cart{}, %Payment{}, %{})
      %Ecto.Changeset{data: %Payment{}}

  """
  def change_payment(%Cart{} = cart, %Payment{} = payment, attrs) do
    cart |> Payment.changeset(payment, attrs)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking payment changes.

  ## Examples

      iex> change_payment(%Cart{}, %{})
      %Ecto.Changeset{data: %Payment{}}

  """
  def change_payment(%Cart{} = cart, attrs \\ %{}) do
    cart |> change_payment(%Payment{}, attrs)
  end

  @doc """
  Updates a payment.

  ## Examples

      iex> update_payment(%{field: "new_value"}, %Account{})
      {:ok, %Payment{}}

      iex> update_payment(%{field: "bad_value"}, %Account{})
      nil

  """
  def update_payment(%{external_id: external_id} = ext_payment, %Account{} = account)
      when is_binary(external_id) do
    payment = account |> get_payment!(external_id)

    payment.cart
    |> change_payment(payment, ext_payment)
    |> update_payment_with_order()
    |> commit_payment_and_order_transaction()
  end

  def update_payment(_attrs, %Account{}), do: nil

  # Only update payments on paid
  defp update_payment_with_order(
         %{
           changes: %{status: "paid"},
           data: %{account: account, cart: cart, order: order}
         } = payment_changeset
       ) do
    Ecto.Multi.new()
    |> PaperTrail.Multi.update(payment_changeset, meta: %{account_id: account.id})
    |> add_order_update(account, cart, order)
  end

  defp update_payment_with_order(%{data: payment}), do: {:ok, payment}

  defp add_order_update(multi, account, %Cart{} = cart, nil) do
    changeset = account |> order_changeset(cart)

    multi
    |> Ecto.Multi.insert(:order, changeset)
    |> Ecto.Multi.run(:order_version, fn repo, _ ->
      PaperTrail.Multi.make_version_struct(
        %{event: "insert"},
        changeset,
        meta: %{account_id: account.id}
      )
      |> repo.insert()
    end)
  end

  defp add_order_update(multi, account, _, %Order{} = order) do
    changeset = order_changeset(account, order)

    multi
    |> Ecto.Multi.update(:order, changeset)
    |> Ecto.Multi.run(:order_version, fn repo, _ ->
      PaperTrail.Multi.make_version_struct(
        %{event: "update"},
        changeset,
        meta: %{account_id: account.id}
      )
      |> repo.insert()
    end)
  end

  defp add_order_update(multi, _account, _cart, _order), do: multi

  defp order_changeset(account, %Cart{} = cart) do
    Sales.change_order(
      account,
      %{
        cart_id: cart.id,
        promotion_expires_at: Timex.now() |> Timex.shift(days: 1),
        data: %{paid: true}
      }
    )
  end

  defp order_changeset(account, %Order{data: data} = order) do
    data =
      case data do
        nil -> %{paid: true}
        data_struct -> data_struct |> Map.from_struct() |> Map.put(:paid, true)
      end

    account |> Sales.change_order(order, %{data: data})
  end

  defp commit_payment_and_order_transaction(multi) do
    case Tq2.Repo.transaction(multi) do
      {:ok, %{model: payment, order: order}} -> {:ok, %{payment | order: order}}
      {:error, _operation, failed_value, _changes} -> {:error, failed_value}
    end
  end

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
