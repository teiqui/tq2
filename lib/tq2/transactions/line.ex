defmodule Tq2.Transactions.Line do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Inventories.Item
  alias Tq2.Transactions.{Cart, Line}

  schema "lines" do
    field :name, :string
    field :quantity, :integer
    field :price, Money.Ecto.Map.Type
    field :promotional_price, Money.Ecto.Map.Type
    field :cost, Money.Ecto.Map.Type

    belongs_to :item, Item
    belongs_to :cart, Cart

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%Cart{} = cart, %Line{} = line, attrs) do
    line
    |> cast(attrs, [:quantity])
    |> validate_required([:item, :quantity])
    |> put_assoc(:cart, cart)
    |> put_item_values(line)
    |> assoc_constraint(:item)
    |> assoc_constraint(:cart)
  end

  defp put_item_values(changeset, %Line{item: nil}) do
    changeset
  end

  defp put_item_values(%{valid?: true} = changeset, %Line{item: item}) do
    change(changeset, %{
      name: item.name,
      price: item.price,
      promotional_price: item.promotional_price,
      cost: item.cost
    })
  end

  defp put_item_values(changeset, _line), do: changeset
end
