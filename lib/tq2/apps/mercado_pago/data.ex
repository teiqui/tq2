defmodule Tq2.Apps.MercadoPago.Data do
  use Ecto.Schema

  import Ecto.Changeset
  import Ecto.Query
  import Tq2Web.Gettext, only: [dgettext: 3]

  alias Tq2.Accounts.Account
  alias Tq2.Apps.MercadoPago, as: MPApp
  alias Tq2.Apps.MercadoPago.Data, as: MPData
  alias Tq2.Gateways.MercadoPago, as: MPClient
  alias Tq2.Gateways.MercadoPago.Credential, as: MPCredential
  alias Tq2.Utils.TrimmedString

  @primary_key false
  embedded_schema do
    field :access_token, TrimmedString
    field :user_id, :string
  end

  @doc false
  def changeset(%MPData{} = data, attrs, %Account{} = account) do
    data
    |> cast(attrs, [:access_token, :user_id])
    |> validate_required([:access_token])
    |> validate_length(:access_token, max: 100)
    |> validate_token()
    |> remote_check_token()
    |> put_user_id()
    |> validate_user_id_uniqueness(account)
  end

  defp validate_token(%Ecto.Changeset{changes: %{access_token: token}} = changeset)
       when is_binary(token) do
    case String.starts_with?(token, valid_token_prefix()) do
      true -> changeset
      _ -> add_error(changeset, :access_token, "is invalid")
    end
  end

  defp validate_token(changeset), do: changeset

  defp remote_check_token(
         %Ecto.Changeset{valid?: true, changes: %{access_token: token}} = changeset
       ) do
    result = %MPCredential{token: token} |> MPClient.check_credentials()

    case result do
      %{"message" => error} ->
        add_error(
          changeset,
          :access_token,
          dgettext("mercado_pago", "Invalid credentials: '%{error}'", error: error)
        )

      _ ->
        changeset
    end
  end

  defp remote_check_token(changeset), do: changeset

  defp put_user_id(%Ecto.Changeset{changes: %{access_token: token}, valid?: true} = changeset) do
    user_id = token |> String.split("-") |> List.last()

    changeset |> change(user_id: user_id)
  end

  defp put_user_id(changeset), do: changeset

  defp validate_user_id_uniqueness(
         %Ecto.Changeset{valid?: true, changes: %{user_id: user_id}} = changeset,
         account
       )
       when is_binary(user_id) do
    exists =
      MPApp
      |> where([mp], mp.name == "mercado_pago" and mp.account_id != ^account.id)
      |> where(fragment("(data ->> 'user_id' = ?)", ^"#{user_id}"))
      |> Tq2.Repo.exists?()

    case exists do
      true -> add_error(changeset, :access_token, "Can't link with a used MercadoPago account")
      _ -> changeset
    end
  end

  defp validate_user_id_uniqueness(changeset, _account), do: changeset

  defp valid_token_prefix() do
    case Application.get_env(:tq2, :env) do
      :prod -> "APP_USR-"
      _ -> "TEST-"
    end
  end
end
