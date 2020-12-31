defmodule Tq2.Analytics.Visit do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Analytics.{Data, Visit}
  alias Tq2.Sales.Order
  alias Tq2.Shares.Token
  alias Tq2.Transactions.Cart

  schema "visits" do
    field :slug, :string
    field :token, :string
    field :referral_token, :string
    field :utm_source, :string

    embeds_one :data, Data

    belongs_to :order, Order
    has_one :cart, Cart

    has_one :destionation_token, Token, foreign_key: :value, references: :token
    has_one :source_token, Token, foreign_key: :value, references: :referral_token

    has_one :customer, through: [:destionation_token, :customer]
    has_one :referral_customer, through: [:source_token, :customer]

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
