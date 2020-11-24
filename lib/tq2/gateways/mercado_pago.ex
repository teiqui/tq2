defmodule Tq2.Gateways.MercadoPago do
  alias Tq2.Gateways.MercadoPago.Credential

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

  # TODO Implement when license has currency & price AND Account. default email
  # def create_license_preference(%License{} = license) do
  #   preference = %{
  #     items: [
  #       %{
  #         title:  dgettext("licenses", "monthly pay"),
  #         description:  dgettext("licenses", "monthly pay"),
  #         quantity: 1,
  #         currency_id: license.currency,
  #         unit_price: License.price_for(license)
  #       }
  #     ],
  #     payer:
  #       %{
  #         email: Accounts.default_email_for(license.account)
  #       },
  #     back_urls: %{
  #       success: license_check_url(),
  #       failure: license_check_url(),
  #       pending: license_check_url()
  #     },
  #     external_reference: license.reference
  #   }

  #   client =
  #     license.currency
  #     |> client_for_currency()

  #   request_post("/checkout/preferences", preference, credential.token)
  # end

  # TODO implement when cart is ready
  # def create_cart_preference(%Credential{} = credential, cart) do
  #   preference = %{
  #     external_reference: cart_external_reference(cart),
  #     items: Enum.map(cart.lines, :to_mercado_pago_item),
  #     payer: %{
  #       name: cart.reservation.customer.name,
  #       surname: cart.reservation.customer.lastname,
  #       email: cart.reservation.customer.email
  #     },
  #     back_urls: %{
  #       success: reservation_thanks_url(),
  #       pending: reservation_thanks_url(),
  #       failure: reservation_payment_url()
  #     }
  #   }

  #   request_post("/checkout/preferences", preference, credential.token)
  # end

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

  @doc "Returns a valid link to associate with marketplace"
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
        "date_approved" => date,
        "status" => status,
        "transaction_amount" => amount
      }) do
    paid_at = date |> parse_date()
    status = status |> parse_payment_status()

    %{
      external_id: id,
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
    "marketplace"
    # Tq2Web.Router.Helpers.license_marketplace_url()
  end

  # defp license_check_url do
  #   # Tq2Web.Router.Helpers.license_check_url()
  # end

  # defp reservation_payment_url do
  #   # Tq2Web.Router.Helpers.mercado_pago_webhooks_url()
  #   # Rails.application.routes.url_helpers.reservation_payment_url account.store
  # end

  # defp reservation_thanks_url do
  #   # Tq2Web.Router.Helpers.mercado_pago_webhooks_url()
  #   # Rails.application.routes.url_helpers.reservation_thanks_url account.store
  # end

  # defp cart_external_reference(cart) do
  #   Enum.join([account.to_param, "cart",  cart.id], "-")
  # end

  defp parse_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    body |> Jason.decode!()
  end

  defp parse_response({:ok, %HTTPoison.Response{status_code: 201, body: body}}) do
    body |> Jason.decode!()
  end

  defp parse_response(response) do
    Sentry.capture_message("MP Error", extra: %{response: response})

    nil
  end

  defp fetch_first_payment(nil), do: nil

  defp fetch_first_payment(%{"results" => results}) do
    results
    |> List.first()
    |> response_to_payment()
  end

  defp parse_date(nil), do: nil

  defp parse_date(raw_datetime) do
    Timex.parse!(raw_datetime, @default_time_format)
  end

  defp parse_payment_status(status) do
    case status do
      s when s in ["approved", "in_process", "authorized"] -> :paid
      s when s in ["rejected", "charged_back", "cancelled", "refunded"] -> :cancelled
      _ -> :pending
    end
  end
end