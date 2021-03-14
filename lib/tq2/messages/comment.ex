defmodule Tq2.Messages.Comment do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Messages.Comment
  alias Tq2.Sales.Order

  schema "comments" do
    field :body, :string
    field :originator, :string, default: "user"
    field :status, :string, default: "created"

    belongs_to :order, Order
    has_one :customer, through: [:order, :customer]

    timestamps updated_at: false, type: :utc_datetime
  end

  @statuses ~w(created delivered read)
  @originators ~w(user customer)

  @doc false
  def changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, [:body, :status, :originator, :order_id])
    |> validate_required([:body, :status, :originator, :order_id])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:originator, @originators)
  end
end
