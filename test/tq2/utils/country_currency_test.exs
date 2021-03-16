defmodule Tq2.Utils.CountryCurrencyTest do
  use Tq2.DataCase, async: true

  alias Tq2.Utils.CountryCurrency

  describe "currencies" do
    test "currency/1 for known countries" do
      ~w(ar cl co gt mx pe)
      |> Enum.each(fn country ->
        assert CountryCurrency.currency(country)
      end)
    end

    test "currency_symbol/1 returns the appropriated symbol" do
      assert CountryCurrency.currency_symbol("ar") == "$"
      assert CountryCurrency.currency_symbol("gt") == "Q"
    end
  end

  describe "countries" do
    test "valid_currencies/0 returns all countries" do
      countries = CountryCurrency.valid_countries()

      assert Enum.count(countries) == 249
    end
  end

  describe "time zones" do
    test "time_zone_or_country_default/2 returns same tz" do
      tz = "America/Argentina/Mendoza"

      assert CountryCurrency.time_zone_or_country_default(tz, "") == tz
    end

    test "time_zone_or_country_default/2 returns default for country" do
      tz = "America/Mexico_City"

      assert CountryCurrency.time_zone_or_country_default("", "mx") == tz
    end

    test "time_zone_or_country_default/2 returns default for unknown country" do
      tz = "America/Argentina/Buenos_Aires"

      assert CountryCurrency.time_zone_or_country_default("", "unknown") == tz
    end
  end

  describe "phones" do
    test "phone_prefix_for_country/1 returns nil for unknwon country code" do
      refute CountryCurrency.phone_prefix_for_country("unkown")
      refute CountryCurrency.phone_prefix_for_country("")
      refute CountryCurrency.phone_prefix_for_country(nil)
    end

    test "phone_prefix_for_country/1 returns correct prefix for country code" do
      assert "+54" == CountryCurrency.phone_prefix_for_country("AR")
      assert "+54" == CountryCurrency.phone_prefix_for_country("ar")

      assert "+1" == CountryCurrency.phone_prefix_for_country("US")

      assert "+52" == CountryCurrency.phone_prefix_for_country("MX")
    end
  end
end
