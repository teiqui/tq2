defmodule Tq2.Apps.WireTransfer do
  @derive {Phoenix.Param, key: :name}

  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.Account
  alias Tq2.Apps.WireTransfer
  alias Tq2.Apps.WireTransfer.Data

  schema "apps" do
    field :name, :string, default: "wire_transfer"
    field :status, :string, default: "active"
    field :lock_version, :integer, default: 0

    embeds_one :data, Data, on_replace: :update

    belongs_to :account, Account

    timestamps()
  end

  @statuses ~w(paused active)

  @doc false
  def changeset(%Account{} = account, %WireTransfer{} = app, attrs) do
    app
    |> cast(attrs, [:status, :lock_version])
    |> cast_embed(:data)
    |> put_account(account)
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
    |> optimistic_lock(:lock_version)
    |> unsafe_validate_unique([:name, :account_id], Tq2.Repo)
    |> unique_constraint([:name, :account_id])
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
