defmodule Tq2Web.RegistrationController do
  use Tq2Web, :controller

  alias Tq2.Accounts

  def show(conn, %{"uuid" => uuid}) do
    registration = Accounts.get_registration!(uuid)
    user = Accounts.get_user(email: registration.email)

    case Accounts.access_registration(registration) do
      {:ok, registration} ->
        conn
        |> put_session(:user_id, user.id)
        |> put_session(:account_id, registration.account_id)
        |> configure_session(renew: true)
        |> redirect(to: Routes.welcome_path(conn, :index))

      {:error, _changeset} ->
        redirect(conn, to: Routes.root_path(conn, :index))
    end
  end
end
