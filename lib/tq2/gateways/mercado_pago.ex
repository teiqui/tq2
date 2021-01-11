defmodule Tq2.Gateways.MercadoPago do
  import Tq2Web.Gettext

  alias Tq2.Gateways.MercadoPago.Credential
  alias Tq2.Transactions.{Cart, Line}
  alias Tq2.Shops.Store

  @default_time_format "{ISO:Extended}"
  @base_uri "https://api.mercadopago.com"
  @min_amounts %{
    "ARS" => 2.0,
    "BRL" => 0.5,
    "CLP" => 1000.0,
    "COP" => 1000.0,
    "MXN" => 5.0,
    "PEN" => 1.0,
    "UYU" => 15.0
  }
  @request_headers %{
    "Accept" => "application/json",
    "Content-Type" => "application/json",
    "User-Agent" => "Teiqui Elixir SDK",
    "x-product-id" => "Tq2",
    "x-tracking-id" => "Teiqui Elixir SDK"
  }

  @commission_urls %{
    "ar" => "https://www.mercadopago.com.ar/ayuda/costo-recibir-pagos_220",
    "br" => "https://www.mercadopago.com.br/ajuda/custo-receber-pagamentos_220",
    "cl" => "https://www.mercadopago.cl/ayuda/costo-recibir-pagos-dinero_220",
    "co" => "https://www.mercadopago.com.co/ayuda/Cu-nto-cuesta-recibir-pagos_220",
    "mx" => "https://www.mercadopago.com.mx/ayuda/costo-recibir-pagos_220",
    "pe" => "https://www.mercadopago.com.pe/ayuda/cuanto-cuesta-recibir-pagos_2430",
    "uy" => "https://www.mercadopago.com.uy/ayuda/recibir-pagos-costos_220"
  }

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
      },
      notification_url: notification_url()
    }

    request_post("/checkout/preferences", preference, credential.token)
  end

  def create_partial_cart_preference(
        %Credential{} = credential,
        %Cart{} = cart,
        %Money{} = pending_amount
      ) do
    preference = %{
      external_reference: cart_external_reference(cart),
      items: pending_payment_items(cart.order, pending_amount),
      payer: %{
        name: cart.customer.name,
        email: cart.customer.email
      }
    }

    request_post("/checkout/preferences", preference, credential.token)
  end

  @doc "Returns a list with valid identification types"
  def check_credentials(%Credential{token: token}) do
    request_get("/v1/identification_types", token)
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

  @doc "Returns a parsed payment map given a MP-payment"
  def response_to_payment(%{
        "external_reference" => external_id,
        "date_approved" => date,
        "status" => status,
        "transaction_amount" => amount,
        "currency_id" => currency
      }) do
    paid_at = date |> parse_date()
    status = status |> parse_payment_status()
    amount = amount |> parse_amount(currency)

    %{
      external_id: external_id,
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
    @commission_urls[country]
  end

  @doc "Returns a list with available countries"
  def countries do
    @commission_urls |> Map.keys()
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

  defp notification_url do
    scheme = if Tq2Web.Endpoint.config(:https), do: "https", else: "http"
    url_config = Tq2Web.Endpoint.config(:url)

    %URI{
      scheme: scheme,
      host: Enum.join([Application.get_env(:tq2, :app_subdomain), url_config[:host]], ".")
    }
    |> Tq2Web.Router.Helpers.webhook_url(:mercado_pago)
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
      s when s in ["rejected", "charged_back", "cancelled", "refunded"] -> "canceled"
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

  defp pending_payment_items(order, pending_amount) do
    amount =
      pending_amount
      |> Money.to_decimal()
      |> Decimal.to_float()

    [
      %{
        title: dgettext("mercado_pago", "Pending amount of order #%{id}", id: order.id),
        description: dgettext("mercado_pago", "Pending amount of order #%{id}", id: order.id),
        currency_id: pending_amount.currency,
        unit_price: amount,
        quantity: 1
      }
    ]
  end
end
