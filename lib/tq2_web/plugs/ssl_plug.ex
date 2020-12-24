defmodule Tq2Web.SSLPlug do
  @moduledoc """
  SSL redirect excluding the health endpoints

  https://github.com/elixir-plug/plug/issues/815
  """

  defdelegate init(opts), to: Plug.SSL

  def call(%{request_path: "/healthy"} = conn, _opts), do: conn
  def call(conn, opts), do: Plug.SSL.call(conn, opts)
end
