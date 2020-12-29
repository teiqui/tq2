defmodule Tq2.Gateways.MercadoPago do
  import Tq2Web.Gettext

  alias Tq2.Accounts
  alias Tq2.Accounts.{Account, License}
  alias Tq2.Gateways.MercadoPago.Credential
  alias Tq2.Payments
  alias Tq2.Transactions.{Cart, Line}
  alias Tq2.Shops.Store

  @default_time_format "{ISO:Extended}"
  @base_uri "https://api.mercadopago.com"
  @min_amounts %{
    "ARS" => 2.0,
    "CLP" => 1000.0,
    "COP" => 1000.0,
    # same than MX
    "GTQ" => 5.0,
    "MXN" => 5.0,
    "PEN" => 1.0
  }
  @request_headers %{
    "Accept" => "application/json",
    "Content-Type" => "application/json",
    "User-Agent" => "Teiqui Elixir SDK",
    "x-product-id" => "Tq2",
    "x-tracking-id" => "Teiqui Elixir SDK"
  }

  @commission_urls %{
    "AR" => "https://www.mercadopago.com.ar/ayuda/costo-recibir-pagos_220",
    "CL" => "https://www.mercadopago.cl/ayuda/costo-recibir-pagos-dinero_220",
    "CO" => "https://www.mercadopago.com.co/ayuda/Cu-nto-cuesta-recibir-pagos_220",
    "MX" => "https://www.mercadopago.com.mx/ayuda/costo-recibir-pagos_220",
    "PE" => "https://www.mercadopago.com.pe/ayuda/cuanto-cuesta-recibir-pagos_2430"
  }

  @doc "Create a license payment preference"
  def create_license_preference(%Account{} = account) do
    credential = account.country |> Credential.for_country()

    preference = %{
      items: [
        %{
          title: dgettext("licenses", "Monthly pay"),
          description: dgettext("licenses", "Monthly pay"),
          quantity: 1,
          currency_id: credential.currency,
          unit_price: License.price_for(account.country)
        }
      ],
      payer: %{
        email: Accounts.get_account_owner!(account).email
      },
      back_urls: %{
        success: license_check_url(),
        failure: license_check_url(),
        pending: license_check_url()
      },
      external_reference: account.license.reference
    }

    request_post("/checkout/preferences", preference, credential.token)
  end

  @doc "Get last payment and update license"
  def update_license_with_last_payment(%Account{} = account) do
    account = Tq2.Repo.preload(account, :license)

    account.country
    |> Credential.for_country()
    |> last_payment_for_reference(account.license.reference)
    |> Payments.create_or_update_license_payment(account)
  end

  def create_cart_preference(%Credential{} = credential, %Cart{} = cart, %Store{} = store) do
    cart = Tq2.Repo.preload(cart, [:customer, :lines])

    preference = %{
      external_reference: cart_external_reference(cart),
      items: Enum.map(cart.lines, &to_mercado_pago_item(&1, cart)),
      payer: %{
        name: cart.customer.name,
        email: cart.customer.email
      },
      back_urls: %{
        success: check_payment_url(store),
        pending: check_payment_url(store),
        failure: store_payment_url(store)
      }
    }

    request_post("/checkout/preferences", preference, credential.token)
  end

  @doc "Returns a map with the payment attributes given an id."
  def get_payment(%Credential{} = credential, id) do
    request_get("/v1/payments/#{id}", credential.token)
  end

  @doc "Returns a map with a parsed payment given a payment reference."
  def last_payment_for_reference(%Credential{} = credential, reference) do
    search_params = %{
      sort: "date_last_updated",
      criteria: "desc",
      external_reference: reference
    }

    "/v1/payments/search"
    |> request_get(search_params, credential.token)
    |> fetch_first_payment()
  end

  @doc "Returns a valid link to bound with marketplace"
  def marketplace_association_link(%Credential{} = credential) do
    params =
      URI.encode_query(%{
        client_id: credential.app_id,
        grant_type: "authorization_code",
        response_type: "code",
        platform_id: "mp"
      })

    Enum.join([
      "https://auth.",
      credential.domain,
      "/authorization?",
      params,
      "&redirect_uri=",
      # redirect uri should not be urlencoded
      license_marketplace_url()
    ])
  end

  @doc "Returns a valid marketplace map"
  def associate_marketplace(%Credential{} = credential, code) do
    request_post(
      "/oauth/token",
      %{
        client_secret: credential.token,
        grant_type: "authorization_code",
        code: code,
        redirect_uri: license_marketplace_url()
      },
      credential.token
    )
  end

  @doc "Returns a parsed payment map given a MP-payment"
  def response_to_payment(%{
        "id" => id,
        "external_reference" => ext_id,
        "date_approved" => date,
        "status" => status,
        "transaction_amount" => amount,
        "currency_id" => currency
      }) do
    paid_at = date |> parse_date()
    status = status |> parse_payment_status()
    amount = amount |> parse_amount(currency)
    # License payment => id
    # Marketplace payment => external_id
    external_id = if String.starts_with?(ext_id, "tq2-mp-cart-"), do: ext_id, else: id

    %{
      external_id: "#{external_id}",
      amount: amount,
      paid_at: paid_at,
      status: status
    }
  end

  def response_to_payment(_), do: %{}

  @doc "Returns the min amount for a given currency"
  def min_amount_for(currency) do
    @min_amounts |> Map.get(currency, 0.0)
  end

  @doc "Returns the commission URL for a given country"
  def commission_url_for(country) do
    @commission_urls[String.upcase(country)]
  end

  defp url_with_token(path, params, token) do
    query_params =
      params
      |> Map.put(:access_token, token)
      |> URI.encode_query()

    "#{@base_uri}#{path}?#{query_params}"
  end

  defp request_get(path, %{} = params \\ %{}, token) do
    path
    |> url_with_token(params, token)
    |> HTTPoison.get(@request_headers)
    |> parse_response()
  end

  defp request_post(path, params, token) do
    json_params = params |> Jason.encode!()

    path
    |> url_with_token(%{}, token)
    |> HTTPoison.post(json_params, @request_headers)
    |> parse_response()
  end

  defp license_marketplace_url do
    app_uri() |> Tq2Web.Router.Helpers.mp_marketplace_url(:show)
  end

  defp license_check_url do
    app_uri() |> Tq2Web.Router.Helpers.license_check_url(:show)
  end

  defp check_payment_url(store) do
    scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
    config = Tq2Web.Endpoint.config(:url)

    %URI{
      scheme: scheme,
      host: "#{Application.get_env(:tq2, :store_subdomain)}.#{config[:host]}"
    }
    |> Tq2Web.Router.Helpers.payment_check_url(:index, store)
  end

  defp store_payment_url(store) do
    scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
    config = Tq2Web.Endpoint.config(:url)

    %URI{
      scheme: scheme,
      host: "#{Application.get_env(:tq2, :store_subdomain)}.#{config[:host]}"
    }
    |> Tq2Web.Router.Helpers.payment_url(:index, store)
  end

  defp cart_external_reference(cart) do
    "tq2-mp-cart-#{cart.id}"
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    body |> Jason.decode!()
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: 201, body: body}}) do
    body |> Jason.decode!()
  end

  defp parse_response({_, %HTTPoison.Response{status_code: code, body: body}}) do
    {_, body} = Jason.decode(body)

    Sentry.capture_message("MP Error", extra: %{body: body, status_code: code})

    body
  end

  defp parse_response(response) do
    Sentry.capture_message("MP Error", extra: %{response: inspect(response)})
  end

  defp fetch_first_payment(nil), do: nil

  defp fetch_first_payment(%{"results" => results}) do
    results
    |> List.first()
    |> response_to_payment()
  end

  defp fetch_first_payment(_), do: nil

  defp parse_date(nil), do: nil

  defp parse_date(raw_datetime) do
    Timex.parse!(raw_datetime, @default_time_format)
  end

  defp parse_payment_status(status) do
    case status do
      s when s in ["approved", "in_process", "authorized"] -> "paid"
      s when s in ["rejected", "charged_back", "cancelled", "refunded"] -> "cancelled"
      _ -> "pending"
    end
  end

  defp parse_amount(amount, currency) do
    {:ok, money} = Money.parse(amount, currency)

    money
  end

  defp to_mercado_pago_item(%Line{} = line, %Cart{price_type: "promotional"}) do
    mp_item_map(line, line.promotional_price)
  end

  defp to_mercado_pago_item(%Line{} = line, %Cart{}) do
    mp_item_map(line, line.price)
  end

  defp mp_item_map(%Line{} = line, %Money{} = price) do
    unit_price =
      price
      |> Money.to_decimal()
      |> Decimal.to_float()

    %{
      id: line.id,
      title: line.name,
      description: line.name,
      currency_id: price.currency,
      unit_price: unit_price,
      quantity: line.quantity
    }
  end

  defp app_uri do
    scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
    url_config = Tq2Web.Endpoint.config(:url)

    %URI{
      scheme: scheme,
      host: Enum.join([Application.get_env(:tq2, :app_subdomain), url_config[:host]], ".")
    }
  end
end
