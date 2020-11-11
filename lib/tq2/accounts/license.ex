defmodule Tq2.Accounts.License do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.{Account, License}
  alias Tq2.Repo

  schema "licenses" do
    field :reference, :string
    field :status, :string
    field :paid_until, :date
    field :lock_version, :integer, default: 0

    belongs_to :account, Account

    timestamps()
  end

  @cast_attrs [:status, :reference, :paid_until, :lock_version]

  @statuses ~w(trial active unpaid locked cancelled)

  @doc false
  def changeset(%License{} = license, attrs) do
    license
    |> cast(attrs, @cast_attrs)
    |> validate()
  end

  @doc false
  def create_changeset(%License{} = license, attrs, %Account{} = account) do
    license
    |> cast(attrs, @cast_attrs)
    |> put_status()
    |> put_paid_until()
    |> put_account(account)
    |> validate()
  end

  defp validate(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:status])
    |> validate_length(:status, max: 255)
    |> validate_inclusion(:status, @statuses)
    |> validate_length(:reference, max: 255)
    |> unsafe_validate_unique(:reference, Repo)
    |> unique_constraint(:reference)
    |> optimistic_lock(:lock_version)
    |> assoc_constraint(:account)
  end

  defp put_status(%Ecto.Changeset{} = changeset) do
    changeset |> change(status: "trial")
  end

  defp put_paid_until(%Ecto.Changeset{} = changeset) do
    next_month = Timex.today() |> Timex.shift(months: 1)

    changeset |> change(paid_until: next_month)
  end

  def put_create_account_attrs(%{name: _} = attrs) do
    Map.put(attrs, :license, %{})
  end

  def put_create_account_attrs(%{"name" => _} = attrs) do
    Map.put(attrs, "license", %{})
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
