defmodule Tq2Web.PasswordViewTest do
  use Tq2Web.ConnCase, async: true

  alias Tq2.Accounts
  alias Tq2.Accounts.User
  alias Tq2Web.PasswordView

  import Phoenix.View

  setup %{conn: conn} do
    conn =
      conn
      |> bypass_through(Tq2Web.Router, :browser)
      |> get("/")

    {:ok, %{conn: conn}}
  end

  test "renders new.html", %{conn: conn} do
    content = render_to_string(PasswordView, "new.html", conn: conn)

    assert String.contains?(content, "Restore password")
  end

  test "renders edit.html", %{conn: conn} do
    user = %User{
      id: "1",
      name: "John",
      lastname: "Doe",
      email: "j@doe.com",
      password_reset_token: "test-token",
      role: "owner"
    }

    changeset = Accounts.change_user_password(user)

    content =
      render_to_string(
        PasswordView,
        "edit.html",
        conn: conn,
        token: user.password_reset_token,
        changeset: changeset
      )

    assert String.contains?(content, "Change password")
  end
end
