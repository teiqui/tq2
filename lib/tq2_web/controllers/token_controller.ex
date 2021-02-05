defmodule Tq2Web.TokenController do
  use Tq2Web, :controller

  def show(conn, %{"slug" => slug, "token" => token}) do
    conn
    |> put_session(:token, token)
    |> redirect(to: Routes.payment_path(conn, :index, slug))
  end
end
