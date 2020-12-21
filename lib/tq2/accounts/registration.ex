defmodule Tq2.Accounts.Registration do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.{Account, Registration}
  alias Tq2.Repo

  @derive {Phoenix.Param, key: :uuid}

  schema "registrations" do
    field :uuid, Ecto.UUID, autogenerate: true
    field :name, :string
    field :type, :string
    field :email, :string

    belongs_to :account, Account

    timestamps()
  end

  @doc false
  def changeset(%Registration{} = registration, attrs) do
    registration
    |> cast(attrs, [:name, :type, :email])
    |> validate_required([:name, :type])
    |> validate_length(:name, max: 255)
    |> validate_length(:type, max: 255)
    |> validate_length(:email, max: 255)
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> unsafe_validate_unique(:email, Repo)
    |> unique_constraint(:uuid)
    |> unique_constraint(:email)
    |> assoc_constraint(:account)
  end
end
