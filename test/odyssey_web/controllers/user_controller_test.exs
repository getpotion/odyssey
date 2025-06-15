defmodule OdysseyWeb.UserControllerTest do
  use OdysseyWeb.ConnCase, async: true

  import Mox

  setup :verify_on_exit!

  setup do
    Mox.stub(Odyssey.EmailMock, :send_verification_email, fn _email, _url -> :ok end)
    :ok
  end

  @valid_user_id "testuser"
  @valid_email "test@example.com"
  @valid_password "password123"

  describe "POST /users/register" do
    test "registers user and returns success message", %{conn: conn} do
      Odyssey.AccountsMock
      |> expect(:register_user, fn %{
                                     user_id: @valid_user_id,
                                     email: @valid_email,
                                     password: @valid_password
                                   } ->
        {:ok, %{id: 1, user_id: @valid_user_id, email: @valid_email}}
      end)

      conn =
        post(conn, "/users/register", %{
          "user_id" => @valid_user_id,
          "email" => @valid_email,
          "password" => @valid_password
        })

      assert json_response(conn, 201)["message"] =~ "User registered. Please verify your email."
    end

    test "returns error for invalid registration", %{conn: conn} do
      Odyssey.AccountsMock
      |> expect(:register_user, fn _ ->
        {:error, %Ecto.Changeset{errors: [user_id: {"can't be blank", []}]}}
      end)

      conn =
        post(conn, "/users/register", %{
          "user_id" => "",
          "email" => @valid_email,
          "password" => @valid_password
        })

      assert json_response(conn, 400)["error"] =~ "user_id can't be blank"
    end
  end

  describe "GET /users/verify/:token" do
    test "verifies account with valid token", %{conn: conn} do
      Odyssey.AccountsMock
      |> expect(:verify_email, fn "validtoken" -> {:ok, %{id: 1}} end)

      conn = get(conn, "/users/verify/validtoken")
      assert json_response(conn, 200)["message"] =~ "Account verified!"
    end

    test "returns error for invalid token", %{conn: conn} do
      Odyssey.AccountsMock
      |> expect(:verify_email, fn "invalidtoken" -> {:error, :invalid_token} end)

      conn = get(conn, "/users/verify/invalidtoken")
      assert json_response(conn, 404)["error"] =~ "Invalid or expired token"
    end

    test "returns error for expired token", %{conn: conn} do
      Odyssey.AccountsMock
      |> expect(:verify_email, fn "expiredtoken" -> {:error, :expired_token} end)

      conn = get(conn, "/users/verify/expiredtoken")
      assert json_response(conn, 410)["error"] =~ "Verification token has expired"
    end
  end
end
