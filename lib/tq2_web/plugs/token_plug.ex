defmodule Tq2Web.TokenPlug do
  import Plug.Conn

  def fetch_token(conn, _opts) do
    case get_session(conn, :token) do
      nil -> create_token(conn)
      _ -> conn
    end
  end

  defp create_token(conn) do
    token = :crypto.strong_rand_bytes(32) |> Base.url_encode64()

    put_session(conn, :token, token)
  end
end
