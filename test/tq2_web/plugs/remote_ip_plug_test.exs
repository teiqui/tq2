defmodule Tq2Web.RemoteIpPlugTest do
  use Tq2Web.ConnCase

  alias Tq2Web.RemoteIpPlug

  describe "remote ip" do
    test "don't do anything if the is no x-forwarded-for header", %{conn: conn} do
      conn = conn |> RemoteIpPlug.put_forwarded_for_remote_ip([])

      assert conn.remote_ip == {127, 0, 0, 1}
    end

    test "extract ip from x-forwarded-for header when is set", %{conn: conn} do
      conn =
        conn
        |> Plug.Conn.put_req_header("x-forwarded-for", "10.0.0.1")
        |> RemoteIpPlug.put_forwarded_for_remote_ip([])

      assert conn.remote_ip == {10, 0, 0, 1}
    end
  end
end
