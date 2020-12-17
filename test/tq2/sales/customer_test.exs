defmodule Tq2.Sales.CustomerTest do
  use Tq2.DataCase, async: true

  describe "customer" do
    alias Tq2.Sales.Customer

    @valid_attrs %{
      name: "some name",
      email: "some@email.com",
      phone: "555-5555",
      address: "some address"
    }
    @invalid_attrs %{
      name: nil,
      email: nil,
      phone: nil,
      address: nil
    }

    test "changeset with valid attributes" do
      changeset = Customer.changeset(%Customer{}, @valid_attrs)

      assert changeset.valid?
    end

    test "changeset with invalid attributes" do
      changeset = Customer.changeset(%Customer{}, @invalid_attrs)

      refute changeset.valid?
    end

    test "changeset does not accept long attributes" do
      attrs =
        @valid_attrs
        |> Map.put(:name, String.duplicate("a", 256))
        |> Map.put(:email, String.duplicate("a", 256))
        |> Map.put(:phone, String.duplicate("5", 256))

      changeset = Customer.changeset(%Customer{}, attrs)

      assert "should be at most 255 character(s)" in errors_on(changeset).name
      assert "should be at most 255 character(s)" in errors_on(changeset).email
      assert "should be at most 255 character(s)" in errors_on(changeset).phone
    end

    test "changeset check basic email format" do
      attrs = Map.put(@valid_attrs, :email, "wrong@email")
      changeset = Customer.changeset(%Customer{}, attrs)

      assert "has invalid format" in errors_on(changeset).email
    end

    test "canonize email" do
      assert "some@email.com" == Customer.canonized_email(" SOME@EMAIL.com ")
      assert nil == Customer.canonized_email("")
      assert nil == Customer.canonized_email(nil)
    end

    test "canonize phone" do
      assert "123456" == Customer.canonized_phone(" 1 x 2 345^6 ")
      assert nil == Customer.canonized_phone("")
      assert nil == Customer.canonized_phone(nil)
    end
  end
end
