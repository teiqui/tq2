defmodule Tq2.Apps.Conekta.Data do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Apps.Conekta.Data
  alias Tq2.Gateways.Conekta, as: CktClient
  alias Tq2.Utils.TrimmedString

  @primary_key false
  embedded_schema do
    field :api_key, TrimmedString
  end

  @cast_attrs [:api_key]

  @doc false
  def changeset(%Data{} = data, attrs) do
    data
    |> cast(attrs, @cast_attrs)
    |> validate_required([:api_key])
    |> validate_length(:api_key, max: 100)
    |> validate_credentials()
  end

  defp validate_credentials(%{changes: %{api_key: _}} = changeset) do
    changeset |> check_credentials()
  end

  defp validate_credentials(changeset), do: changeset

  defp check_credentials(%{changes: %{api_key: key}} = changeset) do
    case CktClient.check_credentials(key) do
      :ok -> changeset
      {:error, error} -> changeset |> add_error(:api_key, error)
    end
  end
end
