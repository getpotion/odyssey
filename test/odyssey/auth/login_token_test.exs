defmodule Odyssey.Auth.LoginTokenTest do
  use Odyssey.DataCase

  alias Odyssey.Auth.LoginToken

  setup do
    # Clear the cache before each test
    Cachex.clear(:login_tokens)
    :ok
  end

  describe "generate_token_id/0" do
    test "generates a token ID" do
      token_id = LoginToken.generate_token_id()
      assert is_binary(token_id)
      assert String.length(token_id) == 16
    end
  end

  describe "store_token/2" do
    test "stores a token in the cache" do
      token_id = LoginToken.generate_token_id()
      user_id = 1
      assert {:ok, true} = LoginToken.store_token(token_id, user_id)
    end
  end

  describe "update_token_status/3" do
    test "updates token status" do
      token_id = LoginToken.generate_token_id()
      user_id = 1
      LoginToken.store_token(token_id, user_id)
      assert {:ok, true} = LoginToken.update_token_status(token_id, :approved, "jwt_token")
    end

    test "returns error for non-existent token" do
      assert {:error, :not_found} = LoginToken.update_token_status("non_existent", :approved)
    end
  end

  describe "get_token/1" do
    test "retrieves a stored token" do
      token_id = LoginToken.generate_token_id()
      user_id = 1
      LoginToken.store_token(token_id, user_id)
      assert {:ok, data} = LoginToken.get_token(token_id)
      assert data.user_id == user_id
      assert data.status == :pending
    end

    test "returns error for non-existent token" do
      assert {:error, :not_found} = LoginToken.get_token("non_existent")
    end
  end
end
