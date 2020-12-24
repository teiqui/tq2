import Ecto.Query

alias Tq2.Repo
alias Tq2.{Accounts, Analytics, Inventories, Sales, Shares, Shops, Transactions}
alias Tq2.Accounts.{Account, License, Session, User}
alias Tq2.Analytics.{View, Visit}
alias Tq2.Inventories.{Category, Item}
alias Tq2.Sales.{Customer, Order}
alias Tq2.Shares.Token
alias Tq2.Shops.Store
alias Tq2.Transactions.{Cart, Line}
