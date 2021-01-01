defmodule Tq2.Sales.Tie do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Sales.{Order, Tie}

  schema "ties" do
    belongs_to :order, Order
    belongs_to :originator, Order

    timestamps()
  end

  @doc false
  def changeset(%Tie{} = tie, attrs) do
    tie
    |> cast(attrs, [:order_id, :originator_id])
    |> assoc_constraint(:order)
    |> assoc_constraint(:originator)
  end
end
