defmodule Tq2.Sales.Customer do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Sales.Customer

  schema "customers" do
    field :address, :string
    field :email, :string
    field :name, :string
    field :phone, :string
    field :lock_version, :integer, default: 0

    timestamps()
  end

  @doc false
  def changeset(%Customer{} = customer, attrs) do
    customer
    |> cast(attrs, [:name, :email, :phone, :address, :lock_version])
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
    |> downcase(:email)
  end

  defp downcase(%Ecto.Changeset{} = changeset, field) do
    update_change(changeset, field, &String.downcase/1)
  end
end
