defmodule Tq2.Apps.WireTransfer.Data do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Apps.WireTransfer.Data

  @primary_key false
  embedded_schema do
    field :description, :string
    field :account_number, :string
  end

  @cast_attrs [
    :description,
    :account_number
  ]

  @doc false
  def changeset(%Data{} = data, attrs) do
    data
    |> cast(attrs, @cast_attrs)
    |> validate_required([:description, :account_number])
    |> validate_length(:description, max: 255)
    |> validate_length(:account_number, max: 255)
  end
end
