defmodule Tq2.Sales do
  @moduledoc """
  The Sales context.
  """

  import Ecto.Query, warn: false

  alias Tq2.Repo
  alias Tq2.Sales.Customer

  @doc """
  Gets a single customer by id.

  Raises `Ecto.NoResultsError` if the Customer does not exist.

  ## Examples

      iex> get_customer!(123)
      %Customer{}

      iex> get_customer!(456)
      ** (Ecto.NoResultsError)

  """
  def get_customer!(id) when is_integer(id) do
    Customer |> Repo.get!(id)
  end

  @doc """
  Gets a single customer by token or by email OR phone.

  Returns nil if the Customer does not exist.

  ## Examples

      iex> get_customer("some_token")
      %Customer{}

      iex> get_customer("invalid_token")
      nil

      iex> get_customer(email: "some@email.com", phone: "555-5555")
      %Customer{}

      iex> get_customer(email: "invalid@email.com", phone: "XXX-XXXX")
      nil

  """
  def get_customer(token) when is_binary(token) do
    Customer
    |> join(:inner, [c], t in assoc(c, :tokens))
    |> where([c, t], t.value == ^token)
    |> Repo.one()
  end

  def get_customer(opts) when is_list(opts) do
    email = Customer.canonized_email(opts[:email]) || "invalid"
    phone = Customer.canonized_phone(opts[:phone]) || "invalid"

    Customer
    |> where([c], c.email == ^email)
    |> or_where([c], c.phone == ^phone)
    |> Repo.one()
  end

  @doc """
  Creates a customer.

  ## Examples

      iex> create_customer(%{field: value})
      {:ok, %Customer{}}

      iex> create_customer(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_customer(attrs) do
    %Customer{}
    |> Customer.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking customer changes.

  ## Examples

      iex> change_customer(customer)
      %Ecto.Changeset{source: %Customer{}}

  """
  def change_customer(%Customer{} = customer, attrs \\ %{}) do
    Customer.changeset(customer, attrs)
  end
end
