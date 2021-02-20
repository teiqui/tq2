defmodule Tq2.Apps.Transbank.Data do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Apps.Transbank.Data
  alias Tq2.Gateways.Transbank, as: TbkClient
  alias Tq2.Utils.TrimmedString

  @primary_key false
  embedded_schema do
    field :api_key, TrimmedString
    field :shared_secret, TrimmedString
  end

  @cast_attrs [:api_key, :shared_secret]

  @doc false
  def changeset(%Data{} = data, attrs) do
    data
    |> cast(attrs, @cast_attrs)
    |> validate_required([:api_key, :shared_secret])
    |> validate_length(:api_key, max: 100)
    |> validate_length(:shared_secret, max: 100)
    |> validate_credentials()
  end

  defp validate_credentials(%{changes: changes} = changeset) do
    case %{} == changes do
      true -> changeset
      false -> check_credentials(changeset)
    end
  end

  defp check_credentials(changeset) do
    api_key = get_field(changeset, :api_key)
    shared_secret = get_field(changeset, :shared_secret)

    case TbkClient.check_credentials(api_key, shared_secret) do
      :ok -> changeset
      {:error, attr, error} -> changeset |> add_error(attr, error)
    end
  end
end
