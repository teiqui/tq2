import Ecto.Query

alias Tq2.Repo
alias Tq2.{Accounts, Inventories, Shops, Transactions}
alias Tq2.Accounts.{Account, License, Session, User}
alias Tq2.Inventories.{Category, Item}
alias Tq2.Shops.Store
alias Tq2.Transactions.{Cart, Line}
