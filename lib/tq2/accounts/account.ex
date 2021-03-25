defmodule Tq2.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  import Tq2.Utils.CountryCurrency, only: [valid_countries: 0]

  alias Tq2.Accounts.{Account, License, Membership}
  alias Tq2.Sales.Order
  alias Tq2.Shops.Store
  alias Tq2.Transactions.Cart
  alias Tq2.Utils.TrimmedString

  @derive {Jason.Encoder, only: [:id, :country, :name, :status, :time_zone, :lock_version]}

  schema "accounts" do
    field :country, :string
    field :name, TrimmedString
    field :status, :string
    field :time_zone, TrimmedString
    field :lock_version, :integer, default: 0

    has_one :license, License
    has_one :store, Store
    has_one :owner_membership, Membership, where: [owner: true]
    has_one :owner, through: [:owner_membership, :user]
    has_many :memberships, Membership
    has_many :orders, Order
    has_many :carts, Cart

    timestamps type: :utc_datetime
  end

  @statuses ~w(green active suspended locked)

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
