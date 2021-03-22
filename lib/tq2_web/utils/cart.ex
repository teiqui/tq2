defmodule Tq2Web.Utils.Cart do
  import Tq2Web.Utils, only: [format_money: 1]
  import Phoenix.HTML, only: [sigil_E: 2]
  import Phoenix.HTML.Tag, only: [img_tag: 2, content_tag: 2]

  alias Tq2.Transactions.Cart

  def line_total(conn, cart, line) do
    regular_total =
      %{cart | price_type: "regular"}
      |> Cart.line_total(line)
      |> format_money()

    promotional_total =
      %{cart | price_type: "promotional"}
      |> Cart.line_total(line)
      |> format_money()

    wrap_line_total(conn, cart, regular_total, promotional_total)
  end

  def cart_promotional_total(%Cart{} = cart) do
    %{cart | price_type: "promotional"}
    |> Cart.total()
    |> format_money()
  end

  def cart_regular_total(%Cart{} = cart) do
    %{cart | price_type: "regular"}
    |> Cart.total()
    |> format_money()
  end

  def cart_total(conn, %Cart{} = cart) do
    total =
      cart
      |> Cart.total()
      |> format_money()

    wrap_cart_total(conn, cart, total)
  end

  def teiqui_logo_img_tag(conn) do
    conn
    |> Tq2Web.Router.Helpers.static_path("/images/favicon.svg")
    |> img_tag(height: 11, width: 11, alt: "Teiqui", class: "mt-n1")
  end

  def line_price(%Cart{price_type: "promotional"}, line) do
    format_money(line.promotional_price)
  end

  def line_price(_, line) do
    format_money(line.price)
  end

  defp wrap_line_total(conn, %Cart{price_type: "promotional"}, regular_total, promotional_total) do
    ~E"""
      <del class="d-block">
        <%= regular_total %>
      </del>
      <div class="text-primary text-nowrap font-weight-bold">
        <%= teiqui_logo_img_tag(conn) %>
        <%= promotional_total %>
      </div>
    """
  end

  defp wrap_line_total(conn, _cart, regular_total, promotional_total) do
    ~E"""
      <div>
        <%= regular_total %>
      </div>
      <del class="d-block text-primary text-nowrap font-weight-bold">
        <%= teiqui_logo_img_tag(conn) %>
        <%= promotional_total %>
      </del>
    """
  end

  defp wrap_cart_total(conn, %Cart{price_type: "promotional"}, total) do
    ~E"""
      <div class="text-primary text-nowrap font-weight-bold">
        <%= teiqui_logo_img_tag(conn) %>
        <%= total %>
      </div>
    """
  end

  defp wrap_cart_total(_conn, _cart, total) do
    content_tag(:div, total)
  end
end
