defmodule Tq2.SalesTest do
  use Tq2.DataCase

  alias Tq2.Sales

  describe "customers" do
    alias Tq2.Sales.Customer

    @valid_attrs %{
      name: "some name",
      email: "some@EMAIL.com",
      phone: "555-5555",
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

    test "get_customer/1 returns the customer with given token" do
      customer = fixture(:customer)

      {:ok, token} =
        Tq2.Shares.create_token(%{
          value: "hItfgIBvse62B_oZPgu6Ppp3qORvjbVCPEi9E-Poz2U=",
          customer_id: customer.id
        })

      assert Sales.get_customer(token.value) == customer
    end

    test "get_customer/1 returns the customer with given email or phone" do
      customer = fixture(:customer)

      assert Sales.get_customer(email: String.upcase(" #{customer.email}")) == customer
      assert Sales.get_customer(phone: String.upcase(" #{customer.phone}x")) == customer
      assert Sales.get_customer(email: customer.email, phone: "non existing 123") == customer
      assert Sales.get_customer(email: "invalid@email.com", phone: "non existing 123") == nil
    end

    test "create_customer/1 with valid data creates a customer" do
      assert {:ok, %Customer{} = customer} = Sales.create_customer(@valid_attrs)
      assert customer.name == @valid_attrs.name
      assert customer.email == Customer.canonized_email(@valid_attrs.email)
      assert customer.phone == Customer.canonized_phone(@valid_attrs.phone)
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
