defmodule Tq2Web.RegistrationControllerTest do
  use Tq2Web.ConnCase

  alias Tq2.Accounts

  @valid_attrs %{
    "name" => "some updated name",
    "type" => "grocery",
    "email" => "some_updated@email.com",
    "password" => "123456",
    "country" => "ar",
    "time_zone" => "America/Argentina/Buenos_Aires",
    "campaign" => nil
  }

  defp fixture(:registration) do
    {:ok, %{account: account, registration: registration}} =
      Accounts.create_registration(@valid_attrs)

    %{registration | account: account}
  end

  describe "show registration" do
    test "assigns current user when registration has not been accessed", %{conn: conn} do
      registration = fixture(:registration)
      user = Accounts.get_user(email: registration.email)
      conn = get(conn, Routes.registration_path(conn, :show, registration))

      assert user.id == get_session(conn, :user_id)
      assert registration.account_id == get_session(conn, :account_id)
      assert redirected_to(conn) == Routes.welcome_path(conn, :index)
    end

    test "assigns current user when registration has been recently accessed", %{conn: conn} do
      registration = fixture(:registration)
      user = Accounts.get_user(email: registration.email)
      {:ok, registration} = Accounts.access_registration(registration)
      conn = get(conn, Routes.registration_path(conn, :show, registration))

      assert user.id == get_session(conn, :user_id)
      assert registration.account_id == get_session(conn, :account_id)
      assert redirected_to(conn) == Routes.welcome_path(conn, :index)
    end

    test "redirect to root when registration has been accessed", %{conn: conn} do
      registration = fixture(:registration)

      {:ok, registration} = Accounts.access_registration(registration)

      three_minutes_ago = Timex.now() |> Timex.shift(minutes: -3) |> DateTime.truncate(:second)

      registration
      |> Ecto.Changeset.change(%{accessed_at: three_minutes_ago})
      |> Tq2.Repo.update!()

      assert_raise Ecto.NoResultsError, fn ->
        get(conn, Routes.registration_path(conn, :show, registration))
      end
    end
  end
end
