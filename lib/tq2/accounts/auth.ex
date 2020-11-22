defmodule Tq2.Accounts.Auth do
  alias Tq2.Repo
  alias Tq2.Accounts.User

  import Argon2, only: [verify_pass: 2, no_user_verify: 0]
  import Ecto.Query, warn: false

  @doc false
  def authenticate_by_email_and_password(email, password) when is_binary(email) do
    email = email |> String.trim() |> String.downcase()

    query =
      from(
        u in User,
        join: m in assoc(u, :memberships),
        where: m.default == true,
        where: u.email == ^email,
        preload: [memberships: m]
      )

    user = Repo.one(query)

    cond do
      user && verify_pass(password, user.password_hash) ->
        {:ok, user}

      true ->
        no_user_verify()

        {:error, :unauthorized}
    end
  end
end
