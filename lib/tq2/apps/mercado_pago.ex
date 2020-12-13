defmodule Tq2.Apps.MercadoPago do
  @derive {Phoenix.Param, key: :name}

  use Ecto.Schema

  import Ecto.Query
  import Ecto.Changeset

  alias Tq2.Apps.MercadoPago
  alias Tq2.Accounts.Account

  schema "apps" do
    field :name, :string, default: "mercado_pago"
    field :status, :string, default: "active"
    field :data, :map, default: %{}
    field :lock_version, :integer, default: 0

    belongs_to :account, Account

    timestamps()
  end

  @statuses ~w(paused active)

  @doc false
  def changeset(%Account{} = account, %MercadoPago{} = app, attrs) do
    app
    |> cast(attrs, [:status, :data, :lock_version])
    |> put_account(account)
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
    |> optimistic_lock(:lock_version)
    |> unsafe_validate_unique([:name, :account_id], Tq2.Repo)
    |> unique_constraint([:name, :account_id])
    |> validate_token()
    |> validate_user_id_uniqueness()
  end

  def full_messages(%Ecto.Changeset{} = changeset) do
    changeset
    |> Ecto.Changeset.traverse_errors(&full_message/3)
    |> Enum.reduce([], fn {_key, errors}, acc -> acc ++ errors end)
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end

  defp validate_token(%Ecto.Changeset{data: %{id: nil}} = changeset) do
    case get_in(changeset.changes, [:data, "access_token"]) do
      t when t in [nil, ""] ->
        add_error(changeset, :data, "Invalid MercadoPago token")

      _ ->
        changeset
    end
  end

  defp validate_token(%Ecto.Changeset{changes: %{data: %{}}} = changeset) do
    empty_map = %{}

    case changeset.changes.data do
      %{"access_token" => t} when t in [nil, ""] ->
        add_error(changeset, :data, "Invalid MercadoPago token")

      ^empty_map ->
        add_error(changeset, :data, "Invalid MercadoPago token")

      _ ->
        changeset
    end
  end

  defp validate_token(changeset), do: changeset

  defp validate_user_id_uniqueness(
         %Ecto.Changeset{valid?: true, changes: %{data: %{"user_id" => user_id}}} = changeset
       ) do
    exists =
      MercadoPago
      |> where(fragment("(data ->> 'user_id' = ?)", ^"#{user_id}"))
      |> where([mp], mp.account_id != ^changeset.changes[:account_id])
      |> Tq2.Repo.exists?()

    case exists do
      true -> add_error(changeset, :data, "Can't link with a used MercadoPago account")
      _ -> changeset
    end
  end

  defp validate_user_id_uniqueness(changeset), do: changeset

  defp full_message(%Ecto.Changeset{}, :data, error) do
    Tq2Web.ErrorHelpers.translate_error(error)
  end

  defp full_message(%Ecto.Changeset{}, key, error) do
    key_name =
      Tq2Web.Gettext
      |> Gettext.dgettext("mercado_pago", "#{key}")
      |> String.capitalize()

    "#{key_name} #{Tq2Web.ErrorHelpers.translate_error(error)}"
  end
end
