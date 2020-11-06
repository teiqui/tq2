# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Tq2.Repo.insert!(%Tq2.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

{:ok, account} =
  Tq2.Accounts.create_account(%{
    name: "Default",
    status: "active",
    country: "ar",
    time_zone: "America/Argentina/Mendoza"
  })

session = %Tq2.Accounts.Session{account: account}

{:ok, _} =
  Tq2.Accounts.create_user(session, %{
    name: "Admin",
    lastname: "Admin",
    email: "admin@tq2.com",
    password: "123456"
  })
