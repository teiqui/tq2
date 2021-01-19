defmodule Tq2.Apps.App do
  @moduledoc """
  The only use for this module is to load all the Apps from database
  """

  @derive {Phoenix.Param, key: :name}

  use Ecto.Schema

  alias Tq2.Accounts.Account

  schema "apps" do
    field :name, :string
    field :status, :string
    field :data, :map
    field :lock_version, :integer, default: 0

    belongs_to :account, Account

    timestamps type: :utc_datetime
  end
end
