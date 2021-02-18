defmodule Tq2.Utils.UrlsTest do
  use Tq2.DataCase, async: true

  alias Tq2.Utils.Urls

  describe "app uri" do
    test "app_uri/0 returns full url with app subdomain" do
      assert URI.to_string(Urls.app_uri()) =~ "http://app.localhost"
    end

    test "app_uri/0 with root url returns full url" do
      root_url =
        Urls.app_uri()
        |> Tq2Web.Router.Helpers.root_url(:index)

      assert root_url =~ "http://app.localhost"
    end
  end

  describe "web uri" do
    test "web_uri/0 returns full url with web subdomain" do
      assert URI.to_string(Urls.web_uri()) =~ "http://www.localhost"
    end

    test "web_uri/0 with root url returns full url" do
      root_url =
        Urls.web_uri()
        |> Tq2Web.Router.Helpers.root_url(:index)

      assert root_url =~ "http://www.localhost"
    end
  end

  describe "store uri" do
    test "store_uri/0 returns full url with store subdomain" do
      assert URI.to_string(Urls.store_uri()) =~
               "http://#{Application.get_env(:tq2, :store_subdomain)}.localhost:#{port()}"
    end

    test "store_uri/0 with root url returns full url" do
      root_url =
        Urls.store_uri()
        |> Tq2Web.Router.Helpers.root_url(:index)

      assert root_url ==
               "http://#{Application.get_env(:tq2, :store_subdomain)}.localhost:#{port()}/"
    end
  end

  defp port do
    Tq2Web.Endpoint.config(:http)[:port]
  end
end
