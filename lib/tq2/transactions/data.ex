defmodule Tq2.Transactions.Data do
  use Ecto.Schema

  import Ecto.Changeset
  import Tq2.Utils.Schema, only: [validate_required_if_field_has_value: 4]

  alias Tq2.Transactions.Data

  embedded_schema do
    field :handing, :string
    field :payment, :string
    field :copied, :boolean, default: false
    field :notified_at, :utc_datetime, default: nil

    embeds_one :shipping, Tq2.Shops.Shipping, on_replace: :delete

    timestamps type: :utc_datetime
  end

  @handing_types ~w(pickup delivery)
  @payment_types ~w(cash conekta mercado_pago transbank wire_transfer)

  @doc false
  def changeset(%Data{} = data, attrs) do
    data
    |> cast(attrs, [:handing, :payment, :copied, :notified_at])
    |> cast_embed(:shipping, with: &shipping_changeset/2)
    |> validate_required([:handing])
    |> validate_inclusion(:handing, @handing_types)
    |> validate_inclusion(:payment, @payment_types)
    |> validate_required_if_field_has_value(:shipping, :handing, "delivery")
  end

  def from_struct(nil), do: Map.from_struct(%Data{})

  def from_struct(%Data{shipping: %{} = shipping} = data) do
    data
    |> Map.from_struct()
    |> Map.put(:shipping, Map.from_struct(shipping))
  end

  def from_struct(%Data{} = data) do
    Map.from_struct(data)
  end

  defp shipping_changeset(data, attrs) do
    data |> cast(attrs, [:id, :name, :price])
  end
end
