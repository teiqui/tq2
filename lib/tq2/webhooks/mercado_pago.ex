defmodule Tq2.Webhooks.MercadoPago do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Webhooks.MercadoPago

  schema "webhooks" do
    field :name, :string, default: "mercado_pago"
    field :payload, :map

    timestamps()
  end

  @doc false
  def changeset(%MercadoPago{} = mercado_pago, attrs) do
    mercado_pago
    |> cast(attrs, [:name, :payload])
    |> validate_required([:name, :payload])
  end
end
