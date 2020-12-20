defmodule Tq2.Analytics.View do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Analytics.{View, Visit}

  schema "views" do
    field :path, :string

    belongs_to :visit, Visit

    timestamps updated_at: false
  end

  @doc false
  def changeset(%View{} = view, attrs) do
    view
    |> cast(attrs, [:path, :visit_id])
    |> cast_assoc(:visit)
    |> validate_required([:path])
    |> validate_length(:path, max: 255)
    |> assoc_constraint(:visit)
  end
end
