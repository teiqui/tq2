defmodule Tq2.Analytics.Visit do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.Account
  alias Tq2.Analytics.{Data, Visit}
  alias Tq2.Sales.Order

  schema "visits" do
    field :token, :string
    field :referral_token, :string
    field :utm_source, :string

    embeds_one :data, Data

    belongs_to :order, Order
    belongs_to :account, Account

    timestamps updated_at: false
  end

  @doc false
  def changeset(%Account{} = account, %Visit{} = visit, attrs) do
    visit
    |> cast(attrs, [:token, :referral_token, :utm_source])
    |> cast_embed(:data)
    |> put_account(account)
    |> validate_required([:token])
    |> validate_length(:token, max: 255)
    |> validate_length(:referral_token, max: 255)
    |> validate_length(:utm_source, max: 255)
    |> assoc_constraint(:order)
    |> assoc_constraint(:account)
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
