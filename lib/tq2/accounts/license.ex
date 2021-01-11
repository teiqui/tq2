defmodule Tq2.Accounts.License do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.{Account, License}
  alias Tq2.Repo

  schema "licenses" do
    field :status, :string
    field :paid_until, :date
    field :lock_version, :integer, default: 0

    # Vendor fields
    field :customer_id, :string
    field :subscription_id, :string

    belongs_to :account, Account

    timestamps()
  end

  @cast_attrs [:status, :customer_id, :subscription_id, :paid_until, :lock_version]

  @statuses ~w(trial active unpaid locked canceled)

  @prices %{
    "ar" => 499.0,
    "cl" => 2800.0,
    "co" => 13800.0,
    "mx" => 80.0,
    "pe" => 14.5,
    "us" => 3.99
  }
  @yearly_prices %{
    "ar" => 4990.0,
    "cl" => 28000.0,
    "co" => 138_000.0,
    "mx" => 800.0,
    "pe" => 145.0,
    "us" => 39.9
  }

  @default_country "us"

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
    |> unsafe_validate_unique(:customer_id, Repo)
    |> unsafe_validate_unique(:subscription_id, Repo)
    |> unique_constraint(:customer_id)
    |> unique_constraint(:subscription_id)
    |> optimistic_lock(:lock_version)
    |> assoc_constraint(:account)
  end

  def price_for(country, :yearly) do
    @yearly_prices[country] || @yearly_prices[@default_country]
  end

  def price_for(country, :monthly) do
    @prices[country] || @prices[@default_country]
  end

  def price_for(country), do: price_for(country, :monthly)

  defp put_status(%Ecto.Changeset{} = changeset) do
    changeset |> change(status: "trial")
  end

  defp put_paid_until(%Ecto.Changeset{} = changeset) do
    trial_until = Timex.today() |> Timex.shift(days: 14)

    changeset |> change(paid_until: trial_until)
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
