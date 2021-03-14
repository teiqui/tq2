defmodule Tq2.Notifications.SubscriptionTest do
  use Tq2.DataCase, async: true

  describe "subscription" do
    alias Tq2.Notifications.Subscription

    @valid_user_attrs %{
      "hash" => "ffed703971737ad05c9f5e9939d5b6434faf0bd9ae0ef95e9ee58b89a8e66b62",
      "error_count" => 0,
      "data" => %{
        "endpoint" => "https://fcm.googleapis.com/fcm/send/some_random_things",
        "keys" => %{"p256dh" => "p256dh_key", "auth" => "auth_string"}
      },
      "subscription_user" => %{
        "user_id" => 1
      }
    }
    @invalid_user_attrs %{
      "hash" => nil,
      "error_count" => nil,
      "data" => %{
        "endpoint" => "",
        "keys" => %{"p256dh" => nil, "auth" => ""}
      },
      "subscription_user" => %{
        "user_id" => nil
      }
    }

    @valid_customer_attrs %{
      "hash" => "ffed703971737ad05c9f5e9939d5b6434faf0bd9ae0ef95e9ee58b89a8e66b62",
      "error_count" => 0,
      "data" => %{
        "endpoint" => "https://fcm.googleapis.com/fcm/send/some_random_things",
        "keys" => %{"p256dh" => "p256dh_key", "auth" => "auth_string"}
      },
      "customer_subscription" => %{
        "customer_id" => 1
      }
    }
    @update_customer_attrs %{
      "hash" => "2259549e5dbdc8d2b2dfb79897a211de914e889026ca9c1956fa00ccef26b80e",
      "error_count" => 0,
      "data" => %{
        "endpoint" => "https://fcm.googleapis.com/fcm/send/some_updated_random_things",
        "keys" => %{"p256dh" => "updated_p256dh_key", "auth" => "updated_auth_string"}
      },
      "customer_subscription" => %{
        "customer_id" => 1
      }
    }
    @invalid_customer_attrs %{
      "hash" => nil,
      "error_count" => nil,
      "data" => %{
        "endpoint" => "",
        "keys" => %{"p256dh" => nil, "auth" => ""}
      },
      "customer_subscription" => %{
        "customer_id" => nil
      }
    }

    test "user_create_changeset with valid attributes" do
      changeset = Subscription.user_create_changeset(%Subscription{}, @valid_user_attrs)

      assert changeset.valid?
    end

    test "user_create_changeset with invalid attributes" do
      changeset = Subscription.user_create_changeset(%Subscription{}, @invalid_user_attrs)

      refute changeset.valid?
    end

    test "customer_create_changeset with valid attributes" do
      changeset = Subscription.customer_create_changeset(%Subscription{}, @valid_customer_attrs)

      assert changeset.valid?
    end

    test "customer_create_changeset with invalid attributes" do
      changeset = Subscription.customer_create_changeset(%Subscription{}, @invalid_customer_attrs)

      refute changeset.valid?
    end

    test "update_changeset with valid attributes" do
      changeset = Subscription.update_changeset(%Subscription{}, @update_customer_attrs)

      assert changeset.valid?
    end

    test "update_changeset with invalid attributes" do
      changeset = Subscription.update_changeset(%Subscription{}, @invalid_customer_attrs)

      refute changeset.valid?
    end

    test "hash endpoint and auth" do
      assert Subscription.hash(@valid_user_attrs) == @valid_user_attrs["hash"]
    end

    test "create_params adds hash and cast expiration time" do
      timestamp = System.os_time(:millisecond)

      data =
        @valid_user_attrs["data"]
        |> Map.put("expirationTime", timestamp)

      attrs =
        @valid_user_attrs
        |> Map.put("hash", nil)
        |> Map.put("data", data)

      casted_attrs = Subscription.create_params(attrs)

      assert casted_attrs["hash"] == @valid_user_attrs["hash"]
      refute casted_attrs["data"]["expirationTime"]

      assert casted_attrs["data"]["expiration_time"] ==
               DateTime.from_unix!(timestamp, :millisecond)

      data =
        @valid_user_attrs["data"]
        |> Map.put("expirationTime", nil)

      attrs =
        @valid_user_attrs
        |> Map.put("hash", nil)
        |> Map.put("data", data)

      casted_attrs = Subscription.create_params(attrs)

      assert casted_attrs["hash"] == @valid_user_attrs["hash"]
      refute casted_attrs["data"]["expirationTime"]
      refute casted_attrs["data"]["expiration_time"]
    end
  end
end
