defmodule OdysseyWeb.API.V1.UserControllerTest do
  @moduledoc """
  Tests for the UserController.
  """

  use OdysseyWeb.ConnCase

  alias Odyssey.Auth.{JWT, LoginToken}
  alias Odyssey.Factory

  setup %{conn: conn} do
    conn = put_req_header(conn, "accept", "application/json")
    # Clear the cache before each test
    Cachex.clear(:login_tokens)
    {:ok, conn: conn}
  end

  describe "login_init/2" do
    test "returns token_id and requires_2fa when user has 2FA enabled", %{conn: conn} do
      user = Factory.insert(:user, two_factor_enabled: true, two_factor_secret: "secret")

      conn =
        post(conn, "/v1/api/login", %{
          email: user.email,
          password: user.password
        })

      assert %{"token_id" => token_id, "requires_2fa" => true} = json_response(conn, 200)
      assert {:ok, %{status: :pending}} = LoginToken.get_token(token_id)
    end

    test "returns token_id and token when user does not have 2FA enabled", %{conn: conn} do
      user = Factory.insert(:user)

      conn =
        post(conn, "/v1/api/login", %{
          email: user.email,
          password: user.password
        })

      assert %{"token_id" => token_id, "requires_2fa" => false} = json_response(conn, 200)
      assert {:ok, %{status: :completed, token: token}} = LoginToken.get_token(token_id)
      assert JWT.verify_token(token)
    end

    test "returns error when credentials are invalid", %{conn: conn} do
      conn =
        post(conn, "/v1/api/login", %{
          email: "invalid@example.com",
          password: "invalid_password"
        })

      assert %{"errors" => %{"detail" => "Invalid credentials"}} = json_response(conn, 401)
    end
  end

  describe "login_poll/2" do
    test "returns token when token is completed", %{conn: conn} do
      user = Factory.insert(:user)
      token_id = LoginToken.generate_token_id()
      token = JWT.generate_token(user)
      LoginToken.store_token(token_id, user.user_id)
      LoginToken.update_token_status(token_id, :completed, token)

      conn = get(conn, ~p"/v1/api/login/poll/#{token_id}")

      assert %{"token" => ^token} = json_response(conn, 200)
    end

    test "returns error when token is pending", %{conn: conn} do
      token_id = LoginToken.generate_token_id()
      LoginToken.store_token(token_id, "user_id")

      conn = get(conn, ~p"/v1/api/login/poll/#{token_id}")

      assert %{"errors" => %{"detail" => "Token not ready"}} = json_response(conn, 404)
    end

    test "returns error when token is not found", %{conn: conn} do
      conn = get(conn, ~p"/v1/api/login/poll/non_existent_token")

      assert %{"errors" => %{"detail" => "Token not found"}} = json_response(conn, 404)
    end
  end

  describe "verify_2fa/2" do
    test "returns token when 2FA code is valid", %{conn: conn} do
      secret = "JBSWY3DPEHPK3PXP"
      user = Factory.insert(:user, two_factor_enabled: true, two_factor_secret: secret)
      token_id = LoginToken.generate_token_id()
      LoginToken.store_token(token_id, user.user_id)
      code = :pot.totp(secret) |> to_string()

      conn =
        post(conn, "/v1/api/login/verify-2fa", %{
          token_id: token_id,
          code: code
        })

      assert %{"token" => token} = json_response(conn, 200)
      assert JWT.verify_token(token)
    end

    test "returns error when 2FA code is invalid", %{conn: conn} do
      user = Factory.insert(:user, two_factor_enabled: true, two_factor_secret: "secret")
      token_id = LoginToken.generate_token_id()
      LoginToken.store_token(token_id, user.user_id)

      conn =
        post(conn, "/v1/api/login/verify-2fa", %{
          token_id: token_id,
          code: "invalid_code"
        })

      assert %{"errors" => %{"detail" => "Invalid 2FA code"}} = json_response(conn, 401)
    end

    test "returns error when token is not found", %{conn: conn} do
      conn =
        post(conn, "/v1/api/login/verify-2fa", %{
          token_id: "non_existent_token",
          code: "valid_code"
        })

      assert %{"errors" => %{"detail" => "Token not found"}} = json_response(conn, 404)
    end

    test "returns error when user is not found", %{conn: conn} do
      token_id = LoginToken.generate_token_id()
      # Store token with a non-existent user_id
      LoginToken.store_token(token_id, "non_existent_user_id")

      conn =
        post(conn, "/v1/api/login/verify-2fa", %{
          token_id: token_id,
          code: "valid_code"
        })

      assert %{"errors" => %{"detail" => "User not found"}} = json_response(conn, 404)
    end
  end
end
