defmodule Tq2Web.RemoteIpPlug do
  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(%Plug.Conn{} = conn, _opts) do
    conn
    |> Plug.Conn.get_req_header("x-forwarded-for")
    |> put_forwarded_for_ip(conn)
  end

  defp put_forwarded_for_ip([], conn) do
    conn
  end

  defp put_forwarded_for_ip([ip | _], conn) do
    case ip |> String.to_charlist() |> :inet.parse_address() do
      {:ok, address} -> %{conn | remote_ip: address}
      _ -> conn
    end
  end
end
