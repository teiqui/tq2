defmodule Tq2.Fixtures do
  import Ecto.Query

  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, Session}

  def user_valid_attrs do
    %{
      email: "some@email.com",
      lastname: "some lastname",
      name: "some name",
      password: "123456",
      role: "owner"
    }
  end

  def user_fixture(%Session{} = session, attrs \\ %{}) do
    user_attrs = Enum.into(attrs, user_valid_attrs())

    {:ok, user} = Accounts.create_user(session, user_attrs)

    %{user | password: nil}
  end

  def default_account do
    Account
    |> where(name: "test_account")
    |> join(:left, [a], l in assoc(a, :license))
    |> preload([a, l], license: l)
    |> Tq2.Repo.one()
  end

  def default_account(_) do
    {:ok, account: default_account()}
  end

  def create_session do
    %Session{account: default_account()}
  end

  def create_session(_) do
    {:ok, session: create_session()}
  end

  def create_customer(attrs \\ %{}) do
    attrs =
      Enum.into(attrs, %{
        name: "some name",
        email: "some@email.com",
        phone: "555-5555",
        address: "some address"
      })

    {:ok, customer} = Tq2.Sales.create_customer(attrs)

    customer
  end
end
