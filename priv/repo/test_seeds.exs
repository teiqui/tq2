# Reset
account = Tq2.Repo.get_by(Tq2.Accounts.Account, name: "test_account")

if account, do: {:ok, _} = Tq2.Accounts.delete_account(account)

# Create

{:ok, _} =
  Tq2.Accounts.create_account(%{
    name: "test_account",
    status: "active",
    country: "ar",
    time_zone: "America/Argentina/Mendoza"
  })
