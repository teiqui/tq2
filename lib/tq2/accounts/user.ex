defmodule Tq2.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias Tq2.Accounts.{Membership, User}
  alias Tq2.Repo
  alias Tq2.Utils.TrimmedString

  @derive {Jason.Encoder, only: [:id, :name, :lastname, :email, :role, :data, :lock_version]}

  schema "users" do
    field :name, TrimmedString
    field :lastname, TrimmedString
    field :email, TrimmedString
    field :password_hash, :string
    field :password, :string, virtual: true
    field :password_reset_token, :string
    field :password_reset_sent_at, :utc_datetime
    field :role, :string, default: "owner"
    field :lock_version, :integer, default: 0

    embeds_one :data, Data do
      field :external_id, :integer
    end

    has_many :memberships, Membership

    timestamps type: :utc_datetime
  end

  @cast_attrs [:name, :lastname, :email, :password, :lock_version]

  @doc false
  def changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, @cast_attrs)
    |> cast_embed(:data, with: &data_changeset/2)
    |> validation()
  end

  @doc false
  def create_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, @cast_attrs)
    |> validate_required([:password])
    |> validation()
  end

  @doc false
  def password_reset_token_changeset(%User{} = user) do
    attrs = %{
      password_reset_token: random_token(64),
      password_reset_sent_at: DateTime.utc_now()
    }

    user
    |> cast(attrs, [:password_reset_token, :password_reset_sent_at])
    |> validate_required([:password_reset_token, :password_reset_sent_at])
  end

  @doc false
  def password_reset_changeset(%User{} = user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 100)
    |> validate_confirmation(:password, required: true)
    |> put_password_hash()
  end

  @doc false
  def data_changeset(schema, params) do
    schema
    |> cast(params, [:external_id])
  end

  defp validation(changeset) do
    changeset
    |> cast_assoc(:memberships)
    |> validate_required([:name, :lastname, :email])
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> validate_length(:name, max: 255)
    |> validate_length(:lastname, max: 255)
    |> validate_length(:email, max: 255)
    |> validate_length(:password, min: 6, max: 100)
    |> validate_confirmation(:password)
    |> unsafe_validate_unique(:email, Repo)
    |> unique_constraint(:email)
    |> optimistic_lock(:lock_version)
    |> downcase(:email)
    |> put_password_hash()
  end

  defp put_password_hash(%{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Argon2.add_hash(password))
  end

  defp put_password_hash(changeset), do: changeset

  defp random_token(length) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  defp downcase(%Ecto.Changeset{} = changeset, field) do
    update_change(changeset, field, &canonize/1)
  end

  defp canonize(nil), do: nil

  defp canonize(string) do
    string |> String.downcase() |> String.trim()
  end
end
