defmodule Tq2.Utils.UrlsTest do
  use Tq2.DataCase, async: true

  alias Tq2.Utils.Urls

  describe "app uri" do
    test "app_uri/0 returns full url with app subdomain" do
      assert URI.to_string(Urls.app_uri()) == "http://app.localhost"
    end

    test "app_uri/0 with root url returns full url" do
      root_url =
        Urls.app_uri()
        |> Tq2Web.Router.Helpers.root_url(:index)

      assert root_url == "http://app.localhost/"
    end
  end
end
