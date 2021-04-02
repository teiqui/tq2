defmodule Tq2.News.Note do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.News.Note
  alias Tq2.Utils.TrimmedString

  schema "notes" do
    field :title, TrimmedString
    field :body, TrimmedString
    field :publish_at, :date
    field :lock_version, :integer, default: 0

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%Note{} = note, attrs) do
    note
    |> cast(attrs, [:title, :body, :publish_at, :lock_version])
    |> validate_required([:title, :body, :publish_at])
    |> validate_length(:title, max: 255)
    |> optimistic_lock(:lock_version)
  end
end
