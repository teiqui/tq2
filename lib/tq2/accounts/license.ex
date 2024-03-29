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

    timestamps type: :utc_datetime
  end

  @cast_attrs [:status, :customer_id, :subscription_id, :paid_until, :lock_version]

  @statuses ~w(trial active unpaid locked canceled)

  @prices %{
    "ar" => Money.parse!("499.0", "ARS"),
    "cl" => Money.parse!("2800.0", "CLP"),
    "co" => Money.parse!("13800.0", "COP"),
    "mx" => Money.parse!("80.0", "MXN"),
    "pe" => Money.parse!("14.5", "PEN"),
    "us" => Money.parse!("3.99", "USD")
  }
  @yearly_prices %{
    "ar" => Money.parse!("4990.0", "ARS"),
    "cl" => Money.parse!("28000.0", "CLP"),
    "co" => Money.parse!("138_000.0", "COP"),
    "mx" => Money.parse!("800.0", "MXN"),
    "pe" => Money.parse!("145.0", "PEN"),
    "us" => Money.parse!("39.9", "USD")
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

  def price_for(country, period \\ :monthly)

  def price_for(%License{account: %{country: country}}, period) do
    price_for(country, period)
  end

  def price_for(country, :yearly) do
    @yearly_prices[country] || @yearly_prices[@default_country]
  end

  def price_for(country, :monthly) do
    @prices[country] || @prices[@default_country]
  end

  defp put_status(%Ecto.Changeset{} = changeset) do
    changeset |> change(status: "trial")
  end

  def put_create_account_attrs(%{name: _} = attrs) do
    Map.put(attrs, :license, attrs_for_campaign(attrs[:campaign]))
  end

  def put_create_account_attrs(%{"name" => _} = attrs) do
    Map.put(attrs, "license", attrs_for_campaign(attrs["campaign"]))
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end

  defp attrs_for_campaign("extended_trial") do
    trial_until = Timex.today() |> Timex.shift(days: 30)

    %{paid_until: trial_until}
  end

  defp attrs_for_campaign(_campaign) do
    trial_until = Timex.today() |> Timex.shift(days: 14)

    %{paid_until: trial_until}
  end
end
