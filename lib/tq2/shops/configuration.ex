defmodule Tq2.Shops.Configuration do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Shops.Configuration

  embedded_schema do
    field :require_email, :boolean, default: false
    field :require_phone, :boolean, default: false
    field :pickup, :boolean, default: false
    field :pickup_time_limit, :string
    field :address, :string
    field :delivery, :boolean, default: false
    field :delivery_area, :string
    field :delivery_time_limit, :string
    field :pay_on_delivery, :boolean, default: false

    timestamps()
  end

  @cast_attrs [
    :require_email,
    :require_phone,
    :pickup,
    :pickup_time_limit,
    :address,
    :delivery,
    :delivery_area,
    :delivery_time_limit,
    :pay_on_delivery
  ]

  @doc false
  def changeset(%Configuration{} = configuration, attrs) do
    configuration
    |> cast(attrs, @cast_attrs)
    |> validate_length(:pickup_time_limit, max: 255)
    |> validate_length(:delivery_time_limit, max: 255)
  end
end
