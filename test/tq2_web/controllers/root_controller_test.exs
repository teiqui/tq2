defmodule Tq2Web.RootControllerTest do
  use Tq2Web.ConnCase

  describe "index" do
    test "redirect to accounts", %{conn: conn} do
      conn = get(conn, Routes.root_path(conn, :index))

      assert redirected_to(conn) == Routes.account_path(conn, :index)
    end
  end
end
