defmodule Tq2.Transactions.Data do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Transactions.Data

  embedded_schema do
    field :handing, :string

    timestamps()
  end

  @handing_types ~w(pickup delivery)

  @doc false
  def changeset(%Data{} = data, attrs) do
    data
    |> cast(attrs, [:handing])
    |> validate_inclusion(:handing, @handing_types)
  end
end
