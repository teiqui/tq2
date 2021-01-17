defmodule Tq2.AnalyticsTest do
  use Tq2.DataCase

  import Tq2.Fixtures, only: [default_account: 0]

  alias Tq2.Analytics

  @valid_visit_attrs %{
    slug: "test",
    token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
    referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
    utm_source: "whatsapp",
    data: %{
      ip: "127.0.0.1"
    }
  }
  @invalid_visit_attrs %{
    slug: nil,
    token: nil,
    referral_token: nil,
    utm_source: nil
  }

  @valid_view_attrs %{
    path: "/",
    visit: %{
      slug: "test",
      token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
      referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
      utm_source: "whatsapp"
    }
  }
  @invalid_view_attrs %{
    path: nil,
    visit_id: nil
  }

  defp fixture(schema, attrs \\ %{})

  defp fixture(:view, attrs) do
    view_attrs = Enum.into(attrs, @valid_view_attrs)

    {:ok, view} = Analytics.create_view(view_attrs)

    view
  end

  defp fixture(:visit, attrs) do
    visit_attrs = Enum.into(attrs, @valid_visit_attrs)

    {:ok, visit} = Analytics.create_visit(visit_attrs)

    visit
  end

  describe "visits" do
    alias Tq2.Analytics.Visit

    test "list_visits/2 returns all visits" do
      visit = fixture(:visit)

      assert Analytics.list_visits(%{}).entries == [visit]
    end

    test "visit_counts/2 returns count for the given period" do
      visit = fixture(:visit)

      assert Analytics.visit_counts(visit.slug) == {1, 0}

      fixture(:visit)
      |> Ecto.Changeset.change(%{
        inserted_at: DateTime.utc_now() |> Timex.shift(days: -1) |> DateTime.truncate(:second)
      })
      |> Tq2.Repo.update!()

      assert Analytics.visit_counts(visit.slug) == {1, 1}
    end

    test "get_visit!/2 returns the visit with given id" do
      visit = fixture(:visit)

      assert Analytics.get_visit!(visit.id).id == visit.id
    end

    test "get_visit!/2 returns the visit with given cart id" do
      visit = fixture(:visit)
      account = default_account()

      {:ok, cart} =
        Tq2.Transactions.create_cart(account, %{
          token: "VsGF8ahAAkIku_fsKztDskgqV7yfUrcGAQsWmgY4B4c=",
          visit_id: visit.id
        })

      assert Analytics.get_visit!(cart_id: cart.id).id == visit.id
    end

    test "create_visit/2 with valid data creates a visit" do
      assert {:ok, %Visit{} = visit} = Analytics.create_visit(@valid_visit_attrs)
      assert visit.slug == @valid_visit_attrs.slug
      assert visit.token == @valid_visit_attrs.token
      assert visit.referral_token == @valid_visit_attrs.referral_token
      assert visit.utm_source == @valid_visit_attrs.utm_source
      assert visit.data.ip == @valid_visit_attrs.data.ip
    end

    test "create_visit/2 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Analytics.create_visit(@invalid_visit_attrs)
    end

    test "change_visit/2 returns a visit changeset" do
      visit = fixture(:visit)

      assert %Ecto.Changeset{} = Analytics.change_visit(visit)
    end
  end

  describe "views" do
    alias Tq2.Analytics.View

    test "list_views/1 returns all views" do
      view = fixture(:view)

      assert Enum.map(Analytics.list_views(%{}).entries, & &1.id) == [view.id]
    end

    test "get_view!/1 returns the view with given id" do
      view = fixture(:view)

      assert Analytics.get_view!(view.id).id == view.id
    end

    test "create_view/1 with valid data creates a view" do
      assert {:ok, %View{} = view} = Analytics.create_view(@valid_view_attrs)
      assert view.path == @valid_view_attrs.path
    end

    test "create_view/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Analytics.create_view(@invalid_view_attrs)
    end

    test "change_view/1 returns a view changeset" do
      view = fixture(:view)

      assert %Ecto.Changeset{} = Analytics.change_view(view)
    end
  end
end
