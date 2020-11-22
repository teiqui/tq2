defmodule Tq2.Shops.Location do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Shops.Location

  embedded_schema do
    field :latitude, :decimal
    field :longitude, :decimal
  end

  @doc false
  def changeset(%Location{} = location, attrs) do
    location
    |> cast(attrs, [:latitude, :longitude])
    |> validate_number(:latitude, less_than_or_equal_to: 180, greater_than_or_equal_to: -180)
    |> validate_number(:longitude, less_than_or_equal_to: 180, greater_than_or_equal_to: -180)
  end
end
