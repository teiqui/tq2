defmodule Tq2.Sales.Data do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Sales.Data

  embedded_schema do
    field :paid, :boolean
    field :notes, :string

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%Data{} = data, attrs) do
    data
    |> cast(attrs, [:paid, :notes])
    |> validate_length(:notes, max: 511)
  end
end
