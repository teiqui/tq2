defmodule Tq2.Shops.Shipping do
  use Ecto.Schema

  import Ecto.Changeset
  import Tq2.Utils.Schema, only: [validate_money: 2]

  alias Tq2.Accounts.Account
  alias Tq2.Shops.Shipping
  alias Tq2.Utils.TrimmedString

  embedded_schema do
    field :name, TrimmedString
    field :price, Money.Ecto.Map.Type

    timestamps inserted_at: false
  end

  @cast_attrs [:name, :price]

  @doc false
  def changeset(%Shipping{} = shipping, attrs, account) do
    attrs = put_currency(account, attrs)

    shipping
    |> cast(attrs, @cast_attrs)
    |> validate_required([:name, :price])
    |> validate_length(:name, max: 255)
    |> validate_money(:price)
  end

  defp put_currency(%Account{country: country}, %{} = attrs) do
    for {field, value} <- attrs, into: attrs do
      {field, cast_to_money(country, field, value)}
    end
  end

  defp cast_to_money(country, field, value)
       when field in [:price, "price"] and is_binary(value) do
    currency = Tq2.Utils.CountryCurrency.currency(country)

    case Money.parse(value, currency) do
      {:ok, money} -> money
      :error -> value
    end
  end

  defp cast_to_money(_country, _field, value), do: value
end
