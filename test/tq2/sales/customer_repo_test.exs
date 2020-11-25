defmodule Tq2.Sales.CustomerRepoTest do
  use Tq2.DataCase

  describe "customer" do
    alias Tq2.Sales
    alias Tq2.Sales.Customer

    @valid_attrs %{
      name: "some name",
      email: "some@email.com",
      phone: "some phone",
      address: "some address"
    }

    def customer_fixture(attrs \\ %{}) do
      customer_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, customer} = Sales.create_customer(customer_attrs)

      customer
    end

    test "converts unique constraint on email to error" do
      customer = customer_fixture(@valid_attrs)
      attrs = Map.put(@valid_attrs, :email, customer.email)
      changeset = Customer.changeset(%Customer{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:email]]
      }

      assert expected == changeset.errors[:email]
    end

    test "converts unique constraint on phone to error" do
      customer = customer_fixture(@valid_attrs)
      attrs = Map.put(@valid_attrs, :phone, customer.phone)
      changeset = Customer.changeset(%Customer{}, attrs)

      expected = {
        "has already been taken",
        [validation: :unsafe_unique, fields: [:phone]]
      }

      assert expected == changeset.errors[:phone]
    end
  end
end
