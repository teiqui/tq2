defmodule Tq2.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  import Tq2.Utils.CountryCurrency, only: [valid_countries: 0]

  alias Tq2.Accounts.{Account, Membership, License}
  alias Tq2.Utils.TrimmedString

  schema "accounts" do
    field :country, :string
    field :name, TrimmedString
    field :status, :string
    field :time_zone, TrimmedString
    field :lock_version, :integer, default: 0

    has_many :memberships, Membership
    has_one :license, License

    timestamps()
  end

  @statuses ~w(green active suspended)

  @doc false
  def changeset(account, attrs) do
    account
    |> put_status()
    |> cast(attrs, [:name, :status, :country, :time_zone, :lock_version])
    |> validate_required([:name, :status, :country, :time_zone])
    |> validate_length(:name, max: 255)
    |> validate_length(:status, max: 255)
    |> validate_inclusion(:country, valid_countries())
    |> validate_inclusion(:status, @statuses)
    |> validate_time_zone(:time_zone)
    |> optimistic_lock(:lock_version)
  end

  @doc false
  def create_changeset(account, attrs) do
    account
    |> changeset(attrs)
    |> cast_assoc(:license, with: {License, :create_changeset, [account]})
  end

  defp put_status(%Account{status: nil} = account) do
    account |> Map.put(:status, "green")
  end

  defp put_status(account), do: account

  def validate_time_zone(changeset, field, options \\ []) do
    validate_change(changeset, field, fn _, time_zone ->
      case Tzdata.zone_exists?(time_zone) do
        true -> []
        false -> [{field, options[:message] || "is invalid"}]
      end
    end)
  end
end
