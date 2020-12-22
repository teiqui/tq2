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
    field :accessed_at, :utc_datetime
    field :password, :string, virtual: true

    belongs_to :account, Account

    timestamps()
  end

  @doc false
  def changeset(%Registration{} = registration, attrs) do
    attrs = canonize(attrs)

    registration
    |> cast(attrs, [:name, :type, :email, :password])
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

  def update_changeset(%Registration{} = registration, attrs) do
    registration
    |> changeset(attrs)
    |> validate_required([:email])
    |> validate_confirmation(:email, required: true)
  end

  def password_changeset(%Registration{} = registration, attrs) do
    registration
    |> changeset(attrs)
    |> validate_required([:password])
    |> validate_confirmation(:password, required: true)
    |> validate_length(:password, min: 6, max: 100)
  end

  def account_changeset(%Registration{} = registration, attrs) do
    registration
    |> changeset(attrs)
    |> cast(attrs, [:account_id])
    |> validate_required([:account_id])
  end

  defp canonize(%{"email" => _} = attrs) do
    attrs
    |> Map.replace("email", canonize(attrs["email"]))
    |> Map.replace("email_confirmation", canonize(attrs["email_confirmation"]))
  end

  defp canonize(%{} = attrs) do
    attrs
    |> Map.replace(:email, canonize(attrs[:email]))
    |> Map.replace(:email_confirmation, canonize(attrs[:email_confirmation]))
  end

  defp canonize(string) when is_binary(string) do
    string |> String.downcase() |> String.trim()
  end

  defp canonize(nil), do: nil
end
