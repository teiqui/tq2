defmodule Tq2.Analytics.Data do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Analytics.Data

  embedded_schema do
    field :ip, :string

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%Data{} = data, attrs) do
    data
    |> cast(attrs, [:ip])
    |> validate_length(:ip, max: 255)
  end
end
