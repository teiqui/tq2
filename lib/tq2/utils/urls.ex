defmodule Tq2.Utils.Urls do
  def app_uri do
    scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
    url_config = Tq2Web.Endpoint.config(:url)

    %URI{
      scheme: scheme,
      host: Enum.join([Application.get_env(:tq2, :app_subdomain), url_config[:host]], ".")
    }
  end
end
