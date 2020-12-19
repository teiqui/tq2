defmodule Tq2.Transactions.Data do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Transactions.Data

  embedded_schema do
    field :handing, :string
    field :payment, :string

    timestamps()
  end

  @handing_types ~w(pickup delivery)
  @payment_types ~w(cash mercado_pago wire_transfer)

  @doc false
  def changeset(%Data{} = data, attrs) do
    data
    |> cast(attrs, [:handing, :payment])
    |> validate_inclusion(:handing, @handing_types)
    |> validate_inclusion(:payment, @payment_types)
  end
end
