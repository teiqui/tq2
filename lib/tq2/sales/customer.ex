defmodule Tq2.Sales.Customer do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Sales.Customer
  alias Tq2.Shares.Token

  schema "customers" do
    field :name, :string
    field :email, :string
    field :address, :string
    field :phone, :string
    field :lock_version, :integer, default: 0

    has_many :tokens, Token

    timestamps()
  end

  @doc false
  def changeset(%Customer{} = customer, attrs) do
    attrs = canonize(attrs)

    customer
    |> cast(attrs, [:name, :email, :phone, :address, :lock_version])
    |> cast_assoc(:tokens)
    |> validate_required([:name])
    |> validate_length(:name, max: 255)
    |> validate_length(:email, max: 255)
    |> validate_length(:phone, max: 255)
    |> validate_format(:email, ~r/.+@.+\..+/)
    |> unsafe_validate_unique(:email, Tq2.Repo)
    |> unsafe_validate_unique(:phone, Tq2.Repo)
    |> unique_constraint(:email)
    |> unique_constraint(:phone)
    |> optimistic_lock(:lock_version)
  end

  @doc false
  def canonized_email(nil), do: nil

  def canonized_email(email) do
    email |> String.downcase() |> String.trim()
  end

  @doc false
  def canonized_phone(nil), do: nil

  def canonized_phone(phone) do
    phone |> String.replace(~r/\D/, "")
  end

  defp canonize(%{"name" => _} = attrs) do
    attrs
    |> Map.replace("email", canonized_email(attrs["email"]))
    |> Map.replace("phone", canonized_phone(attrs["phone"]))
  end

  defp canonize(%{} = attrs) do
    attrs
    |> Map.replace(:email, canonized_email(attrs[:email]))
    |> Map.replace(:phone, canonized_phone(attrs[:phone]))
  end
end
