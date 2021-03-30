defmodule Tq2.Sales.Customer do
  use Ecto.Schema

  import Ecto.Changeset
  import Tq2.Utils.Schema, only: [validate_phone_number: 3]

  alias Tq2.Notifications.CustomerSubscription
  alias Tq2.Sales.Customer
  alias Tq2.Shares.Token
  alias Tq2.Shops.Store
  alias Tq2.Utils.TrimmedString

  schema "customers" do
    field :name, TrimmedString
    field :email, TrimmedString
    field :address, TrimmedString
    field :phone, TrimmedString
    field :lock_version, :integer, default: 0
    field :subscribe, :boolean, default: true, virtual: true

    has_many :tokens, Token
    has_many :customer_subscriptions, CustomerSubscription
    has_many :subscriptions, through: [:customer_subscriptions, :subscription]

    timestamps type: :utc_datetime
  end

  @doc false
  def changeset(%Customer{} = customer, attrs, store \\ nil) do
    attrs = canonize(attrs)

    customer
    |> cast(attrs, [:name, :email, :phone, :address, :subscribe, :lock_version])
    |> cast_assoc(:tokens)
    |> validate(store)
  end

  @doc false
  def update_changeset(%Customer{} = customer, attrs, store \\ nil) do
    attrs = canonize(attrs)

    customer
    |> cast(attrs, [:name, :email, :phone, :address, :subscribe, :lock_version])
    |> validate(store)
  end

  defp validate(%Ecto.Changeset{} = changeset, store) do
    changeset
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
    |> validate_store_required(:email, store)
    |> validate_store_required(:phone, store)
    |> validate_store_required(:address, store)
    |> validate_phone(store)
  end

  @doc false
  def canonized_email(nil), do: nil

  def canonized_email(email) do
    email |> String.downcase() |> String.trim()
  end

  @doc false
  def canonized_phone(nil), do: nil

  def canonized_phone(phone) do
    phone |> String.replace(~r/[^0-9\+\-]/, "")
  end

  @doc false
  def random_token do
    :crypto.strong_rand_bytes(32) |> Base.url_encode64()
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

  defp validate_store_required(changeset, :email, %Store{configuration: %{require_email: true}}) do
    changeset |> validate_required([:email])
  end

  defp validate_store_required(changeset, :phone, %Store{configuration: %{require_phone: true}}) do
    changeset |> validate_required([:phone])
  end

  defp validate_store_required(changeset, :address, %Store{
         configuration: %{require_address: true}
       }) do
    changeset |> validate_required([:address])
  end

  defp validate_store_required(changeset, _field, _store), do: changeset

  defp validate_phone(changeset, %Store{account: %{country: country}}) do
    changeset |> validate_phone_number(:phone, country)
  end

  defp validate_phone(changeset, _store), do: changeset
end
