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
end
