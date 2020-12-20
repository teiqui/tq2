defmodule Tq2.Analytics.Visit do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Analytics.{Data, Visit}
  alias Tq2.Sales.Order

  schema "visits" do
    field :slug, :string
    field :token, :string
    field :referral_token, :string
    field :utm_source, :string

    embeds_one :data, Data

    belongs_to :order, Order

    timestamps updated_at: false
  end

  @doc false
  def changeset(%Visit{} = visit, attrs) do
    visit
    |> cast(attrs, [:slug, :token, :referral_token, :utm_source])
    |> cast_embed(:data)
    |> validate_required([:slug, :token])
    |> validate_length(:slug, max: 255)
    |> validate_length(:token, max: 255)
    |> validate_length(:referral_token, max: 255)
    |> validate_length(:utm_source, max: 255)
    |> assoc_constraint(:order)
  end
end
