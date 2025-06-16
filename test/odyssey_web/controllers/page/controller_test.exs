defmodule OdysseyWeb.Page.ControllerTest do
  use OdysseyWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Phoenix Framework"
  end
end
