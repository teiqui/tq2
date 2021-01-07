defmodule Tq2.Payments.LicensePayment do
  use Ecto.Schema

  import Ecto.Changeset
  import Tq2.Utils.Schema, only: [validate_money: 2]

  alias Tq2.Accounts.Account
  alias Tq2.Payments.LicensePayment, as: LPayment

  @statuses ~w(pending paid cancelled)

  @cast_attrs ~w(external_id amount status paid_at lock_version)a

  schema "license_payments" do
    field :amount, Money.Ecto.Map.Type
    field :paid_at, :utc_datetime
    field :external_id, :string
    field :status, :string
    field :lock_version, :integer, default: 0

    belongs_to :account, Account
    has_one :license, through: [:account, :license]

    timestamps()
  end

  @doc false
  def changeset(%Account{} = account, %LPayment{} = payment, attrs) do
    payment
    |> cast(attrs, @cast_attrs)
    |> put_account(account)
    |> validate_required([:external_id, :amount, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:external_id, max: 255)
    |> unsafe_validate_unique(:external_id, Tq2.Repo)
    |> unique_constraint(:external_id)
    |> validate_money(:amount)
    |> assoc_constraint(:account)
    |> optimistic_lock(:lock_version)
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
