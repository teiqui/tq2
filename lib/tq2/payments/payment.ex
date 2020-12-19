defmodule Tq2.Payments.Payment do
  use Ecto.Schema

  import Ecto.Changeset
  import Tq2.SchemaUtils, only: [validate_money: 2]

  alias Tq2.Payments.Payment
  alias Tq2.Transactions.Cart

  schema "payments" do
    field :status, :string
    field :kind, :string
    field :amount, Money.Ecto.Map.Type
    field :external_id, :string
    field :gateway_data, :map
    field :lock_version, :integer, default: 0

    belongs_to :cart, Cart

    timestamps()
  end

  @cast_attrs [
    :status,
    :kind,
    :amount,
    :external_id,
    :gateway_data,
    :lock_version
  ]
  @statuses ~w(pending paid)
  @kinds ~w(cash mercado_pago wire_transfer)

  @doc false
  def changeset(%Cart{} = cart, %Payment{} = payment, attrs) do
    payment
    |> cast(attrs, @cast_attrs)
    |> put_assoc(:cart, cart)
    |> validate_required([:status, :kind, :amount])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:kind, @kinds)
    |> validate_money(:amount)
    |> validate_length(:external_id, max: 255)
    |> unsafe_validate_unique(:external_id, Tq2.Repo)
    |> unique_constraint(:external_id)
    |> assoc_constraint(:cart)
    |> optimistic_lock(:lock_version)
  end
end
