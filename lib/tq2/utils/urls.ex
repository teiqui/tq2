defmodule Tq2.Utils.Urls do
  def app_uri do
    %URI{
      host: Enum.join([Application.get_env(:tq2, :app_subdomain), host()], "."),
      port: port(),
      scheme: scheme()
    }
  end

  def web_uri do
    %URI{
      host: Enum.join([Application.get_env(:tq2, :web_subdomain), host()], "."),
      port: port(),
      scheme: scheme()
    }
  end

  def store_uri do
    %URI{
      host: Enum.join([Application.get_env(:tq2, :store_subdomain), host()], "."),
      port: port(),
      scheme: scheme()
    }
  end

  defp host, do: Tq2Web.Endpoint.config(:url)[:host]

  defp port do
    unless Application.get_env(:tq2, :env) == :prod do
      Tq2Web.Endpoint.config(:http)[:port]
    end
  end

  defp scheme do
    if Application.get_env(:tq2, :env) == :prod do
      "https"
    else
      "http"
    end
  end
end
