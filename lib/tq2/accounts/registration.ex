defmodule Tq2.Accounts.Registration do
  use Ecto.Schema

  import Ecto.Changeset
  import Tq2.Utils.Schema, only: [validate_phone_number: 3]

  alias Tq2.Accounts.{Account, Registration}
  alias Tq2.Repo
  alias Tq2.Utils.TrimmedString

  @derive {Phoenix.Param, key: :uuid}

  schema "registrations" do
    field :uuid, Ecto.UUID, autogenerate: true
    field :name, TrimmedString
    field :type, TrimmedString
    field :email, TrimmedString
    field :phone, TrimmedString
    field :accessed_at, :utc_datetime
    field :password, :string, virtual: true
    field :country, :string, virtual: true

    belongs_to :account, Account

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%Registration{} = registration, attrs) do
    attrs = canonize(attrs)

    registration
    |> cast(attrs, [:name, :type, :email, :phone, :password])
    |> validate_required([:name, :type, :email, :phone, :password])
    |> validate_length(:name, max: 255)
    |> validate_length(:type, max: 255)
    |> validate_length(:email, max: 255)
    |> validate_length(:phone, max: 255)
    |> validate_length(:password, min: 6, max: 100)
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> validate_phone_number(:phone, registration.country)
    |> unsafe_validate_unique(:email, Repo)
    |> unsafe_validate_unique(:phone, Repo)
    |> unique_constraint(:uuid)
    |> unique_constraint(:email)
    |> unique_constraint(:phone)
    |> assoc_constraint(:account)
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
