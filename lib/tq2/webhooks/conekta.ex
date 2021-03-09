defmodule Tq2.Webhooks.Conekta do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Webhooks.Conekta

  schema "webhooks" do
    field :name, :string, default: "conekta"
    field :payload, :map

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%Conekta{} = conekta, attrs) do
    conekta
    |> cast(attrs, [:name, :payload])
    |> validate_required([:name, :payload])
  end
end
