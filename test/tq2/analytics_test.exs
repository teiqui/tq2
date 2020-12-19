defmodule Tq2.AnalyticsTest do
  use Tq2.DataCase

  alias Tq2.Analytics

  describe "visits" do
    setup [:create_session]

    alias Tq2.Analytics.Visit

    @valid_attrs %{
      token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
      referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
      utm_source: "whatsapp",
      data: %{
        ip: "127.0.0.1"
      }
    }
    @invalid_attrs %{
      token: nil,
      referral_token: nil,
      utm_source: nil
    }

    defp create_session(_) do
      account = Tq2.Repo.get_by!(Tq2.Accounts.Account, name: "test_account")

      {:ok, session: %Tq2.Accounts.Session{account: account}}
    end

    defp fixture(session, :visit, attrs \\ %{}) do
      visit_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, visit} = Analytics.create_visit(session.account, visit_attrs)

      visit
    end

    test "list_visits/2 returns all visits", %{session: session} do
      visit = fixture(session, :visit)

      assert Analytics.list_visits(session.account, %{}).entries == [visit]
    end

    test "get_visit!/2 returns the visit with given id", %{session: session} do
      visit = fixture(session, :visit)

      assert Analytics.get_visit!(session.account, visit.id) == visit
    end

    test "create_visit/2 with valid data creates a visit", %{session: session} do
      assert {:ok, %Visit{} = visit} = Analytics.create_visit(session.account, @valid_attrs)
      assert visit.token == @valid_attrs.token
      assert visit.referral_token == @valid_attrs.referral_token
      assert visit.utm_source == @valid_attrs.utm_source
      assert visit.data.ip == @valid_attrs.data.ip
    end

    test "create_visit/2 with invalid data returns error changeset", %{session: session} do
      assert {:error, %Ecto.Changeset{}} = Analytics.create_visit(session.account, @invalid_attrs)
    end

    test "change_visit/2 returns a visit changeset", %{session: session} do
      visit = fixture(session, :visit)

      assert %Ecto.Changeset{} = Analytics.change_visit(session.account, visit)
    end
  end
end
