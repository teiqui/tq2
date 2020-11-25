defmodule Tq2.SalesTest do
  use Tq2.DataCase

  alias Tq2.Sales

  describe "customers" do
    alias Tq2.Sales.Customer

    @valid_attrs %{
      name: "some name",
      email: "some@email.com",
      phone: "some phone",
      address: "some address"
    }
    @invalid_attrs %{
      name: nil,
      email: nil,
      phone: nil,
      address: nil
    }

    defp fixture(:customer, attrs \\ %{}) do
      customer_attrs = Enum.into(attrs, @valid_attrs)

      {:ok, customer} = Sales.create_customer(customer_attrs)

      customer
    end

    test "get_customer!/1 returns the customer with given id" do
      customer = fixture(:customer)

      assert Sales.get_customer!(customer.id) == customer
    end

    test "create_customer/1 with valid data creates a customer" do
      assert {:ok, %Customer{} = customer} = Sales.create_customer(@valid_attrs)
      assert customer.name == @valid_attrs.name
      assert customer.email == @valid_attrs.email
      assert customer.phone == @valid_attrs.phone
      assert customer.address == @valid_attrs.address
    end

    test "create_customer/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sales.create_customer(@invalid_attrs)
    end

    test "change_customer/1 returns a customer changeset" do
      customer = fixture(:customer)

      assert %Ecto.Changeset{} = Sales.change_customer(customer)
    end
  end
end
