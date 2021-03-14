defmodule Tq2.Notifications.Data do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Notifications.Data

  @primary_key false

  embedded_schema do
    field :endpoint, :string
    field :expiration_time, :utc_datetime

    embeds_one :keys, Keys, on_replace: :update, primary_key: false do
      field :auth, :string
      field :p256dh, :string
    end
  end

  @doc false
  def changeset(%Data{} = data, attrs) do
    data
    |> cast(attrs, [:endpoint, :expiration_time])
    |> cast_embed(:keys, with: &keys_changeset/2)
    |> validate_required([:endpoint])
  end

  defp keys_changeset(data, attrs) do
    data |> cast(attrs, [:auth, :p256dh])
  end
end
