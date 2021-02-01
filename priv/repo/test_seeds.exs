# Reset
account = Tq2.Repo.get_by(Tq2.Accounts.Account, name: "test_account")

if account, do: {:ok, _} = Tq2.Accounts.delete_account(account)

# Create

{:ok, account} =
  Tq2.Accounts.create_account(%{
    name: "test_account",
    status: "active",
    country: "ar",
    time_zone: "America/Argentina/Mendoza"
  })

{:ok, _} =
  Tq2.Shops.create_store(
    %Tq2.Accounts.Session{account: account},
    %{
      name: "some name",
      description: "some description",
      slug: "some_slug",
      published: true,
      account_id: account.id,
      data: %{
        phone: "555-5555",
        email: "store@some_slug.com",
        whatsapp: "+549555-5555",
        facebook: "some facebook",
        instagram: "some instagram"
      },
      configuration: %{
        require_email: true,
        require_phone: true,
        pickup: true,
        pickup_time_limit: "some time limit",
        address: "some address",
        delivery: true,
        delivery_area: "some delivery area",
        delivery_time_limit: "some time limit",
        pay_on_delivery: true,
        shippings: %{"0" => %{"name" => "Anywhere", "price" => "10.00"}}
      },
      location: %{
        latitude: "12",
        longitude: "123"
      }
    }
  )
