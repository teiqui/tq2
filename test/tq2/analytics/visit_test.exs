defmodule Tq2.Analytics.VisitTest do
  use Tq2.DataCase, async: true

  describe "visit" do
    alias Tq2.Analytics.Visit

    @valid_attrs %{
      slug: "test",
      token: "IXFz6ntHSmfmY2usXsXHu4WAU-CFJ8aFvl5xEYXi6bk=",
      referral_token: "N68iU2uIe4SDO1W50JVauF2PJESWoDxlHTl1RSbr3Z4=",
      utm_source: "whatsapp"
    }
    @invalid_attrs %{
      slug: nil,
      token: nil,
      referral_token: nil,
      utm_source: nil
    }

    test "changeset with valid attributes" do
      changeset = Visit.changeset(%Visit{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Visit.changeset(%Visit{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:slug, String.duplicate("a", 256))
        |> Map.put(:token, String.duplicate("a", 256))
        |> Map.put(:referral_token, String.duplicate("a", 256))
        |> Map.put(:utm_source, String.duplicate("a", 256))

      changeset = Visit.changeset(%Visit{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).slug
      assert "should be at most 255 character(s)" in errors_on(changeset).token
      assert "should be at most 255 character(s)" in errors_on(changeset).referral_token
      assert "should be at most 255 character(s)" in errors_on(changeset).utm_source
    end
  end
end
