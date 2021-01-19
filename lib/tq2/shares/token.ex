defmodule Tq2.Shares.Token do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Sales.Customer
  alias Tq2.Shares.Token

  schema "tokens" do
    field :value, :string

    belongs_to :customer, Customer

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%Token{} = token, attrs) do
    token
    |> cast(attrs, [:value, :customer_id])
    |> validate_required([:value])
    |> validate_length(:value, max: 255)
    |> unique_constraint(:value)
  end
end
