defmodule Tq2.Shops.Configuration do
  use Ecto.Schema

  import Ecto.Changeset
  import Tq2Web.Gettext, only: [dgettext: 2]

  import Tq2.Utils.Schema,
    only: [
      validate_at_least_one_active: 3,
      validate_required_if_present: 3,
      validate_at_least_one_embed_if_active: 4
    ]

  alias Tq2.Shops.{Configuration, Shipping}

  embedded_schema do
    field :require_email, :boolean, default: false
    field :require_phone, :boolean, default: false
    field :require_address, :boolean, default: false
    field :pickup, :boolean, default: false
    field :pickup_time_limit, :string
    field :address, :string
    field :delivery, :boolean, default: false
    field :delivery_area, :string
    field :delivery_time_limit, :string
    field :pay_on_delivery, :boolean, default: false

    embeds_many :shippings, Shipping, on_replace: :delete

    timestamps type: :utc_datetime
  end

  @cast_attrs [
    :require_email,
    :require_phone,
    :require_address,
    :pickup,
    :pickup_time_limit,
    :address,
    :delivery,
    :delivery_area,
    :delivery_time_limit,
    :pay_on_delivery
  ]

  @doc false
  def changeset(%Configuration{} = configuration, attrs, account) do
    configuration
    |> cast(attrs, @cast_attrs)
    |> cast_embed(:shippings, with: {Shipping, :changeset, [account]})
    |> validate_required_if_present(:pickup_time_limit, :pickup)
    |> validate_required_if_present(:delivery_time_limit, :delivery)
    |> validate_required_if_present(:delivery_area, :delivery)
    |> validate_length(:pickup_time_limit, max: 255)
    |> validate_length(:delivery_time_limit, max: 255)
    |> validate_at_least_one_active([:pickup, :delivery], &translate_field/1)
    |> validate_at_least_one_embed_if_active(
      :shippings,
      :delivery,
      &at_least_one_shipping_translation/0
    )
  end

  def translate_field(:pickup) do
    dgettext("stores", "Pickup")
  end

  def translate_field(:delivery) do
    dgettext("stores", "Delivery")
  end

  def at_least_one_shipping_translation do
    dgettext("stores", "Add at least one shipping")
  end

  def from_struct(nil), do: Map.from_struct(%Configuration{})

  def from_struct(%Configuration{shippings: [_ | _] = shippings} = config) do
    s = shippings |> Enum.map(&Map.from_struct(&1))

    config
    |> Map.from_struct()
    |> Map.put(:shippings, s)
  end

  def from_struct(%Configuration{} = config) do
    Map.from_struct(config)
  end
end
