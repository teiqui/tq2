defmodule Tq2.Accounts.RegistrationTest do
  use Tq2.DataCase, async: true

  describe "registration" do
    alias Tq2.Accounts.Registration

    @valid_attrs %{
      name: "some name",
      type: "grocery",
      email: "some@email.com"
    }
    @invalid_attrs %{
      name: nil,
      type: nil,
      email: nil
    }

    @valid_update_attrs %{
      name: "some updated name",
      type: "grocery",
      email: "some_updated@email.com",
      email_confirmation: "some_updated@email.com"
    }
    @invalid_update_attrs %{
      name: nil,
      type: nil,
      email: "some@email.com",
      email_confirmation: "other@email.com"
    }

    test "changeset with valid attributes" do
      changeset = Registration.changeset(%Registration{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Registration.changeset(%Registration{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "update changeset with valid attributes" do
      changeset = Registration.update_changeset(%Registration{}, @valid_update_attrs)

      assert changeset.valid?
    end

    test "update changeset with invalid attributes" do
      changeset = Registration.update_changeset(%Registration{}, @invalid_update_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:name, String.duplicate("a", 256))
        |> Map.put(:type, String.duplicate("a", 256))
        |> Map.put(:email, String.duplicate("a", 256))

      changeset = Registration.changeset(%Registration{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).name
      assert "should be at most 255 character(s)" in errors_on(changeset).type
      assert "should be at most 255 character(s)" in errors_on(changeset).email
    end

    test "update changeset requires valid email confirmation" do
      attrs =
        @valid_update_attrs
        |> Map.put(:email_confirmation, "wrong@email.com")

      changeset = Registration.update_changeset(%Registration{}, attrs)

      assert "does not match confirmation" in errors_on(changeset).email_confirmation
    end
  end
end
