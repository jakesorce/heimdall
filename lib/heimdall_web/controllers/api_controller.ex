require Integer
require Decimal

defmodule HeimdallWeb.ApiController do
  use HeimdallWeb, :controller
  import Plug.Conn

  # this route takes one upc, and returns the upc with the check digit added
  # http://0.0.0.0:4000/api/add_check_digit/1234
  def add_check_digit(conn, params) do
    check_digit_with_upc = _calculate_check_digit(params["upc"])
    _send_json(conn, 200, check_digit_with_upc)
  end

  # this route takes a comma separated list and should add a check digit to each element
  # http://0.0.0.0:4000/api/add_a_bunch_of_check_digits/12345,233454,34341432
  def add_a_bunch_of_check_digits(conn, params) do
    check_digits_with_upc = String.split(params["upcs"], ",")
    |> tl
    |> Enum.map((fn upc -> _calculate_check_digit(upc) end))

    _send_json(conn, 200, check_digits_with_upc)
  end

  # these are private methods
  defp _calculate_check_digit(upc) do
    alias Integer, as: I

    digits = String.to_integer(upc)
    |> Integer.digits
    |> Enum.with_index

    odd_total = Enum.filter(digits, fn({_k, index}) -> I.is_even(index) end)
    |> Enum.reduce(0, fn(x, acc) -> elem(x, 0) + acc end)
    |> Kernel.*(3)

    even_total = Enum.filter(digits, fn({_k, index}) -> I.is_odd(index) end)
    |> Enum.reduce(0, fn(x, acc) -> elem(x, 0) + acc end)

    check_digit = rem(odd_total + even_total, 10)
    if (check_digit == 0), do: check_digit, else: 10 - check_digit
  end

  # this is a thing to format your responses and return json to the client
  defp _send_json(conn, status, body) do
    conn
    |> put_resp_header("content-type", "application/json")
    |> send_resp(status, Poison.encode!(body))
  end

end
