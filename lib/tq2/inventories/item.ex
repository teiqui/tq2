defmodule Tq2.Inventories.Item do
  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Inventories.{Category, Item}
  alias Tq2.Accounts.Account

  schema "items" do
    field :uuid, :string
    field :sku, :string
    field :name, :string
    field :description, :string
    field :visibility, :string, default: "visible"
    field :price, Money.Ecto.Map.Type
    field :promotional_price, Money.Ecto.Map.Type
    field :cost, Money.Ecto.Map.Type
    field :image, Tq2.ImageUploader.Type
    field :lock_version, :integer, default: 0

    belongs_to :account, Account
    belongs_to :category, Category

    timestamps()
  end

  @cast_attrs [
    :sku,
    :name,
    :description,
    :visibility,
    :price,
    :promotional_price,
    :cost,
    :category_id,
    :lock_version
  ]
  @visibilities ~w(visible hidden)

  @money_attrs ~w(price promotional_price cost) ++ ~w(price promotional_price cost)a

  @doc false
  def changeset(%Account{} = account, %Item{} = item, attrs) do
    attrs = put_currency(account, attrs)

    item
    |> put_uuid()
    |> cast(attrs, @cast_attrs)
    |> cast_attachments(attrs, [:image])
    |> put_account(account)
    |> validate_required([:uuid, :name, :visibility, :price, :promotional_price, :cost])
    |> validate_length(:uuid, max: 255)
    |> validate_length(:sku, max: 255)
    |> validate_length(:name, max: 255)
    |> validate_inclusion(:visibility, @visibilities)
    |> validate_money(:price)
    |> validate_money(:promotional_price)
    |> validate_money(:cost)
    |> unsafe_validate_unique([:sku, :account_id], Tq2.Repo)
    |> unsafe_validate_unique([:name, :account_id], Tq2.Repo)
    |> unique_constraint(:uuid)
    |> unique_constraint([:sku, :account_id])
    |> unique_constraint([:name, :account_id])
    |> assoc_constraint(:account)
    |> assoc_constraint(:category)
    |> optimistic_lock(:lock_version)
  end

  defp put_currency(%Account{country: country}, %{} = attrs) do
    for {field, value} <- attrs, into: attrs do
      {field, cast_to_money(country, field, value)}
    end
  end

  defp put_uuid(%Item{uuid: nil} = item) do
    item |> Map.put(:uuid, Ecto.UUID.generate())
  end

  defp put_uuid(item), do: item

  defp cast_to_money(country, field, value) when field in @money_attrs and is_binary(value) do
    currency =
      %{
        "ar" => :ARS,
        "cl" => :CLP,
        "co" => :COP,
        "gt" => :GTQ,
        "mx" => :MXN,
        "pe" => :PEN
      }[country]

    case Money.parse(value, currency) do
      {:ok, money} -> money
      :error -> value
    end
  end

  defp cast_to_money(_country, _field, value), do: value

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end

  defp validate_money(changeset, field) do
    validate_change(changeset, field, fn
      _, %Money{amount: amount} when amount >= 0 -> []
      _, _ -> [{field, {"must be greater than or equal to %{number}", number: 0}}]
    end)
  end
end
