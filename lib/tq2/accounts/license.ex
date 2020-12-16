defmodule Tq2.Accounts.License do
  use Ecto.Schema

  import Ecto.Changeset

  alias Tq2.Accounts.{Account, License}
  alias Tq2.Repo

  schema "licenses" do
    field :reference, Ecto.UUID, autogenerate: true
    field :status, :string
    field :paid_until, :date
    field :lock_version, :integer, default: 0

    belongs_to :account, Account

    timestamps()
  end

  @cast_attrs [:status, :reference, :paid_until, :lock_version]

  @statuses ~w(trial active unpaid locked cancelled)

  @currencies %{
    "ar" => "ARS",
    "cl" => "CLP",
    "co" => "COP",
    "gt" => "MXN",
    "mx" => "MXN",
    "pe" => "PEN"
  }
  @prices %{
    "ARS" => 990.0,
    "CLP" => 20_000.0,
    "COP" => 58_000.0,
    "MXN" => 330.0,
    "PEN" => 48.0
  }
  @yearly_prices %{
    "ARS" => 5_940.0,
    "CLP" => 120_000.0,
    "COP" => 348_000.0,
    "MXN" => 1_980.0,
    "PEN" => 288.0
  }

  @doc false
  def changeset(%License{} = license, attrs) do
    license
    |> cast(attrs, @cast_attrs)
    |> validate()
  end

  @doc false
  def create_changeset(%License{} = license, attrs, %Account{} = account) do
    license
    |> cast(attrs, @cast_attrs)
    |> put_status()
    |> put_paid_until()
    |> put_account(account)
    |> validate()
  end

  defp validate(%Ecto.Changeset{} = changeset) do
    changeset
    |> validate_required([:status])
    |> validate_length(:status, max: 255)
    |> validate_inclusion(:status, @statuses)
    |> unsafe_validate_unique(:reference, Repo)
    |> unique_constraint(:reference)
    |> optimistic_lock(:lock_version)
    |> assoc_constraint(:account)
  end

  def price_for(country, :yearly) do
    currency = @currencies[country]

    @yearly_prices[currency]
  end

  def price_for(country, :monthly) do
    currency = @currencies[country]

    @prices[currency]
  end

  def price_for(country), do: price_for(country, :monthly)

  def put_paid_until_changes(license, %Ecto.Changeset{} = payment_cs) do
    {status, months} =
      case payment_cs.changes[:status] do
        "paid" -> {"active", 1}
        "cancelled" -> {"unpaid", -1}
        _ -> {license.status, 0}
      end

    paid_until = license.paid_until |> Timex.shift(months: months)

    attrs = %{status: status, paid_until: paid_until}

    License.changeset(license, attrs)
  end

  def add_changeset_to_multi(%Ecto.Changeset{} = changeset, multi) do
    # Handle PaperTrail manually update because of the multi returned "keys"
    # https://github.com/izelnakri/paper_trail/blob/master/lib/paper_trail/multi.ex#L108
    multi
    |> Ecto.Multi.update(:license, changeset)
    |> Ecto.Multi.run(:license_version, fn repo, _ ->
      PaperTrail.Multi.make_version_struct(
        %{event: "update"},
        changeset,
        meta: %{account_id: changeset.data.account_id}
      )
      |> repo.insert()
    end)
  end

  defp put_status(%Ecto.Changeset{} = changeset) do
    changeset |> change(status: "trial")
  end

  defp put_paid_until(%Ecto.Changeset{} = changeset) do
    next_month = Timex.today() |> Timex.shift(months: 1)

    changeset |> change(paid_until: next_month)
  end

  def put_create_account_attrs(%{name: _} = attrs) do
    Map.put(attrs, :license, %{})
  end

  def put_create_account_attrs(%{"name" => _} = attrs) do
    Map.put(attrs, "license", %{})
  end

  defp put_account(%Ecto.Changeset{} = changeset, %Account{} = account) do
    changeset |> change(account_id: account.id)
  end
end
