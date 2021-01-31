defmodule Tq2.Utils.Urls do
  def app_uri do
    %URI{
      scheme: scheme(),
      host: Enum.join([Application.get_env(:tq2, :app_subdomain), url_config(:host)], ".")
    }
  end

  def web_uri do
    %URI{
      scheme: scheme(),
      host: Enum.join([Application.get_env(:tq2, :web_subdomain), url_config(:host)], ".")
    }
  end

  def store_uri do
    %URI{
      scheme: scheme(),
      host: Enum.join([Application.get_env(:tq2, :store_subdomain), url_config(:host)], ".")
    }
  end

  defp url_config(key) do
    Tq2Web.Endpoint.config(:url)[key]
  end

  defp scheme do
    if Application.get_env(:tq2, :env) == :prod do
      "https"
    else
      "http"
    end
  end
end
