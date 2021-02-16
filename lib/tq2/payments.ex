defmodule Tq2.Payments do
  @moduledoc """
  The Payments context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Accounts.{Account, Session}
  alias Tq2.Payments.Payment
  alias Tq2.Repo
  alias Tq2.Trail
  alias Tq2.Sales
  alias Tq2.Sales.Order
  alias Tq2.Transactions.Cart

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
  Get a pending payment by kind and cart token

  ## Examples

      iex> get_pending_payment_for_cart_and_kind(%Cart{}, "mercado_pago")
      %Payment{}

      iex> get_pending_payment_for_cart_and_kind(%Cart{}, "kind")
      ** (Ecto.NoResultsError)

  """
  def get_pending_payment_for_cart_and_kind(%Cart{id: id}, kind) do
    Payment |> Repo.get_by(cart_id: id, status: "pending", kind: kind)
  end

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
  Creates a payment.

  ## Examples

      iex> create_payment(%Session{}, %Cart{}, %{field: value})
      {:ok, %Payment{}}

      iex> create_payment(%Session{}, %Cart{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_payment(%Session{account: account, user: user}, %Cart{} = cart, attrs) do
    cart
    |> Payment.changeset(%Payment{}, attrs)
    |> Trail.insert(originator: user, meta: %{account_id: account.id})
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
  Updates a payment from an external_id.

  ## Examples

      iex> update_payment_by_external_id(%{external_id: "new_value"}, %Account{})
      {:ok, %Payment{}}

      iex> update_payment_by_external_id(%{external_id: 123}, %Account{})
      nil

  """
  def update_payment_by_external_id(
        %{external_id: external_id} = ext_payment,
        %Account{} = account
      )
      when is_binary(external_id) do
    payment = account |> get_payment!(external_id)
    cart = %{payment.cart | account: account}

    cart
    |> change_payment(payment, ext_payment)
    |> update_payment_with_order()
    |> commit_payment_and_order_transaction()
  end

  def update_payment_by_external_id(_attrs, %Account{}), do: nil

  @doc """
  Updates a payment from an external_id.

  ## Examples

      iex> update_payment(%Cart{}, %Payment{}, %{field: new_value})
      {:ok, %Payment{}}

      iex> update_payment(%Cart{}, %Payment{}, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_payment(%Cart{} = cart, %Payment{} = payment, attrs) do
    cart
    |> change_payment(payment, attrs)
    |> Trail.update(meta: %{account_id: cart.account_id})
  end

  @doc """
  Deletes a payment.

  ## Examples

      iex> delete_payment(%Session{}, %Payment{})
      {:ok, %Payment{}}

      iex> delete_payment(%Session{}, %Payment{})
      {:error, %Ecto.Changeset{}}
  """
  def delete_payment(%Session{account: account, user: user}, %Payment{} = payment) do
    Trail.delete(payment, originator: user, meta: %{account_id: account.id})
  end

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
end
