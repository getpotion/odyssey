defmodule Odyssey.Auth.JWTTest do
  use Odyssey.DataCase

  alias Odyssey.Auth.JWT

  describe "generate_token/1" do
    test "generates a JWT token for a user" do
      user = %{user_id: 1, email: "test@example.com"}
      token = JWT.generate_token(user)
      assert is_binary(token)
    end
  end

  describe "verify_token/1" do
    test "verifies a valid JWT token" do
      user = %{user_id: 1, email: "test@example.com"}
      token = JWT.generate_token(user)
      assert {:ok, claims} = JWT.verify_token(token)
      assert claims["user_id"] == 1
      assert claims["email"] == "test@example.com"
    end

    test "returns error for an invalid token" do
      assert {:error, _reason} = JWT.verify_token("invalid_token")
    end
  end
end
