defmodule Tq2.Shops.Store do
  use Ecto.Schema
  use Waffle.Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.Account
  alias Tq2.Shops.{Configuration, Data, Location, Store}
  alias Tq2.Utils.TrimmedString

  @derive {Phoenix.Param, key: :slug}

  schema "stores" do
    field :uuid, Ecto.UUID, autogenerate: true
    field :name, TrimmedString
    field :description, :string
    field :slug, :string
    field :published, :boolean, default: true
    field :logo, Tq2.LogoUploader.Type
    field :lock_version, :integer, default: 0

    embeds_one :data, Data
    embeds_one :configuration, Configuration
    embeds_one :location, Location

    belongs_to :account, Account

    timestamps type: :utc_datetime
  end

  @cast_attrs [:name, :description, :slug, :published, :lock_version]

  @doc false
  def changeset(%Account{} = account, %Store{} = store, attrs) do
    store
    |> put_uuid()
    |> cast(attrs, @cast_attrs)
    |> cast_attachments(attrs, [:logo])
    |> cast_embed(:data)
    |> cast_embed(:configuration)
    |> cast_embed(:location)
    |> put_account(account)
    |> validate_required([:uuid, :name, :slug, :published])
    |> validate_length(:name, max: 255)
    |> validate_length(:slug, max: 255)
    |> validate_format(:slug, ~r/\A[\w\-_]+\z/)
    |> downcase(:slug)
    |> unsafe_validate_unique(:slug, Tq2.Repo)
    |> unique_constraint(:uuid)
    |> unique_constraint(:slug)
    |> assoc_constraint(:account)
    |> optimistic_lock(:lock_version)
  end

  def slugified(name) do
    name
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9\s-]/, "")
    |> String.replace(~r/(\s|-)+/, "_")
  end

  defp put_uuid(%Store{uuid: nil} = store) do
    store |> Map.put(:uuid, Ecto.UUID.generate())
  end

  defp put_uuid(store), do: store

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end

  defp downcase(%Ecto.Changeset{} = changeset, field) do
    update_change(changeset, field, &String.downcase/1)
  end
end
