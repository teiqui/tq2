defmodule Tq2.Shops.Data do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Shops.Data
  alias Tq2.Utils.TrimmedString

  embedded_schema do
    field :phone, TrimmedString
    field :email, TrimmedString
    field :whatsapp, TrimmedString
    field :facebook, TrimmedString
    field :instagram, TrimmedString

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%Data{} = data, attrs) do
    data
    |> cast(attrs, [:phone, :email, :whatsapp, :facebook, :instagram])
    |> validate_length(:phone, max: 255)
    |> validate_length(:email, max: 255)
    |> validate_length(:whatsapp, max: 255)
    |> validate_length(:facebook, max: 255)
    |> validate_length(:instagram, max: 255)
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> downcase(:email)
  end

  defp downcase(%Ecto.Changeset{} = changeset, field) do
    update_change(changeset, field, &String.downcase/1)
  end
end
