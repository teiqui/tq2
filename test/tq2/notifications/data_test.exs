defmodule Tq2.Notifications.DataTest do
  use Tq2.DataCase, async: true

  describe "data" do
    alias Tq2.Notifications.Data

    @valid_attrs %{
      "endpoint" => "https://fcm.googleapis.com/fcm/send/some_random_things",
      "keys" => %{"p256dh" => "p256dh_key", "auth" => "auth_string"}
    }
    @invalid_attrs %{
      "endpoint" => "",
      "keys" => %{"p256dh" => nil, "auth" => ""}
    }

    test "changeset with valid attributes" do
      changeset = Data.changeset(%Data{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Data.changeset(%Data{}, @invalid_attrs)

      refute changeset.valid?
    end
  end
end
