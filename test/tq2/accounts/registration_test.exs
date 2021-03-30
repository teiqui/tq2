defmodule Tq2.Accounts.RegistrationTest do
  use Tq2.DataCase, async: true

  describe "registration" do
    alias Tq2.Accounts.Registration

    @valid_attrs %{
      name: "some name",
      type: "grocery",
      email: "some@email.com",
      phone: "+54 555-5555",
      password: "123456"
    }

    @invalid_attrs %{
      name: "",
      type: nil,
      email: nil,
      phone: nil,
      password: nil
    }

    test "changeset with valid attributes" do
      changeset = Registration.changeset(%Registration{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Registration.changeset(%Registration{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:name, String.duplicate("a", 256))
        |> Map.put(:type, String.duplicate("a", 256))
        |> Map.put(:email, String.duplicate("a", 256))
        |> Map.put(:phone, String.duplicate("a", 256))

      changeset = Registration.changeset(%Registration{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).name
      assert "should be at most 255 character(s)" in errors_on(changeset).type
      assert "should be at most 255 character(s)" in errors_on(changeset).email
      assert "should be at most 255 character(s)" in errors_on(changeset).phone
    end

    test "account changeset requires account id" do
      changeset = Registration.account_changeset(%Registration{}, @valid_attrs)

      assert "can't be blank" in errors_on(changeset).account_id
    end
  end
end
