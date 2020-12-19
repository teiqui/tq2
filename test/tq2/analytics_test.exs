defmodule Tq2.AnalyticsTest do
  use Tq2.DataCase

  alias Tq2.Analytics

  @valid_visit_attrs %{
    token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
    referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
    utm_source: "whatsapp",
    data: %{
      ip: "127.0.0.1"
    }
  }
  @invalid_visit_attrs %{
    token: nil,
    referral_token: nil,
    utm_source: nil
  }

  @valid_view_attrs %{
    path: "/",
    visit: %{
      token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
      referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
      utm_source: "whatsapp"
    }
  }
  @invalid_view_attrs %{
    path: nil,
    visit_id: nil
  }

  defp create_session(_) do
    account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")

    {:ok, session: %Tq2.Accounts.Session{account: account}}
  end

  defp fixture(session, schema, attrs \\ %{})

  defp fixture(session, :view, attrs) do
    view_attrs = Enum.into(attrs, @valid_view_attrs)

    {:ok, view} = Analytics.create_view(session.account, view_attrs)

    view
  end

  defp fixture(session, :visit, attrs) do
    visit_attrs = Enum.into(attrs, @valid_visit_attrs)

    {:ok, visit} = Analytics.create_visit(session.account, visit_attrs)

    visit
  end

  describe "visits" do
    setup [:create_session]

    alias Tq2.Analytics.Visit

    test "list_visits/2 returns all visits", %{session: session} do
      visit = fixture(session, :visit)

      assert Analytics.list_visits(session.account, %{}).entries == [visit]
    end

    test "get_visit!/2 returns the visit with given id", %{session: session} do
      visit = fixture(session, :visit)

      assert Analytics.get_visit!(session.account, visit.id) == visit
    end

    test "create_visit/2 with valid data creates a visit", %{session: session} do
      assert {:ok, %Visit{} = visit} = Analytics.create_visit(session.account, @valid_visit_attrs)
      assert visit.token == @valid_visit_attrs.token
      assert visit.referral_token == @valid_visit_attrs.referral_token
      assert visit.utm_source == @valid_visit_attrs.utm_source
      assert visit.data.ip == @valid_visit_attrs.data.ip
    end

    test "create_visit/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} =
               Analytics.create_visit(session.account, @invalid_visit_attrs)
    end

    test "change_visit/2 returns a visit changeset", %{session: session} do
      visit = fixture(session, :visit)

      assert %Ecto.Changeset{} = Analytics.change_visit(session.account, visit)
    end
  end

  describe "views" do
    setup [:create_session]

    alias Tq2.Analytics.View

    test "list_views/2 returns all views", %{session: session} do
      view = fixture(session, :view)

      assert Enum.map(Analytics.list_views(session.account, %{}).entries, & &1.id) == [view.id]
    end

    test "get_view!/2 returns the view with given id", %{session: session} do
      view = fixture(session, :view)

      assert Analytics.get_view!(session.account, view.id).id == view.id
    end

    test "create_view/2 with valid data creates a view", %{session: session} do
      assert {:ok, %View{} = view} = Analytics.create_view(session.account, @valid_view_attrs)
      assert view.path == @valid_view_attrs.path
    end

    test "create_view/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} =
               Analytics.create_view(session.account, @invalid_view_attrs)
    end

    test "change_view/2 returns a view changeset", %{session: session} do
      view = fixture(session, :view)

      assert %Ecto.Changeset{} = Analytics.change_view(session.account, view)
    end
  end
end
