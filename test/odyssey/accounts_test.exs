defmodule Odyssey.AccountsTest do
  @moduledoc """
  Tests for the Accounts module.
  """

  use Odyssey.DataCase

  alias Odyssey.Accounts
  alias Odyssey.Factory

  setup do
    user_id = Faker.UUID.v4()
    email = Faker.Internet.email()
    password = Faker.String.base64(12)
    {:ok, %{user_id: user_id, email: email, password: password}}
  end

  @doc """
  Tests the register_user/1 function.
  """
  describe "register_user/1" do
    test "registers a user with valid data", %{user_id: user_id, email: email, password: password} do
      assert {:ok, user} = Accounts.register_user(%{user_id: user_id, email: email, password: password})
      assert user.user_id == user_id
      assert user.email == email
      assert user.password_hash
      assert user.verification_token
      assert user.verification_token_expires_at
      assert user.email_verified_at == nil
      assert user.two_factor_enabled == false
      assert user.two_factor_secret == nil
      assert user.recovery_codes == []
    end

    test "returns error with invalid data" do
      assert {:error, _changeset} = Accounts.register_user(%{})
    end

    test "registration with existing user_id" do
      user_id = Faker.UUID.v4()
      attrs1 = %{user_id: user_id, email: Faker.Internet.email(), password: Faker.String.base64(12)}
      attrs2 = %{user_id: user_id, email: Faker.Internet.email(), password: Faker.String.base64(12)}
      {:ok, _} = Accounts.register_user(attrs1)
      assert {:error, changeset} = Accounts.register_user(attrs2)
      assert "User ID already exists" in Map.get(errors_on(changeset), :user_id, [])
    end

    test "registration with existing email" do
      email = Faker.Internet.email()
      attrs1 = %{user_id: Faker.UUID.v4(), email: email, password: Faker.String.base64(12)}
      attrs2 = %{user_id: Faker.UUID.v4(), email: email, password: Faker.String.base64(12)}
      {:ok, _} = Accounts.register_user(attrs1)
      assert {:error, changeset} = Accounts.register_user(attrs2)
      assert "Email already exists" in Map.get(errors_on(changeset), :email, [])
    end
  end

  @doc """
  Tests the verify_email/1 function.
  """
  describe "verify_email/1" do
    test "verifies user with valid token" do
      user = Factory.insert(:user)

      assert {:ok, verified_user} = Accounts.verify_email(user.verification_token)
      assert verified_user.email_verified_at
    end

    test "returns error with invalid token" do
      assert {:error, :invalid_token} = Accounts.verify_email("invalid_token")
    end

    test "returns error with expired token" do
      token = "valid_token_#{System.unique_integer()}"

      expires_at =
        DateTime.utc_now()
        |> DateTime.add(-3600)
        |> DateTime.to_naive()
        |> NaiveDateTime.truncate(:second)

      _user =
        Factory.insert(:user, %{verification_token: token, verification_token_expires_at: expires_at})

      assert {:error, :expired_token} = Accounts.verify_email(token)
    end
  end

  @doc """
  Tests the get_user_by_user_id/1 function.
  """
  describe "get_user_by_user_id/1" do
    test "returns user when user exists" do
      user = Factory.insert(:user)

      assert {:ok, found_user} = Accounts.get_user_by_user_id(user.user_id)
      assert found_user.user_id == user.user_id
    end

    test "returns error when user does not exist" do
      assert {:error, :not_found} = Accounts.get_user_by_user_id("non_existent_user_id")
    end
  end

  @doc """
  Tests the get_user_by_email/1 function.
  """
  describe "get_user_by_email/1" do
    test "returns user when user exists" do
      user = Factory.insert(:user)

      assert found_user = Accounts.get_user_by_email(user.email)
      assert found_user.email == user.email
    end

    test "returns nil when user does not exist" do
      assert is_nil(Accounts.get_user_by_email("non_existent_email"))
    end
  end

  @doc """
  Tests the get_user_by_verification_token/1 function.
  """
  describe "get_user_by_verification_token/1" do
    test "returns user when token exists" do
      token = "valid_token_#{System.unique_integer()}"

      expires_at =
        DateTime.utc_now()
        |> DateTime.add(3600)
        |> DateTime.to_naive()
        |> NaiveDateTime.truncate(:second)

      _user =
        Factory.insert(:user, %{verification_token: token, verification_token_expires_at: expires_at})

      assert found_user = Accounts.get_user_by_verification_token(token)
      assert found_user.verification_token == token
    end

    test "returns nil when token does not exist" do
      assert is_nil(Accounts.get_user_by_verification_token("non_existent_token"))
    end
  end

  @doc """
  Tests the authenticate_user/2 function.
  """
  describe "authenticate_user/2" do
    test "authenticates user with valid credentials", %{email: email, password: password} do
      user = Factory.insert(:user, email: email, password: password)

      assert {:ok, authenticated_user} = Accounts.authenticate_user(email, password)
      assert authenticated_user.user_id == user.user_id
    end

    test "returns error with invalid password", %{email: email} do
      _user = Factory.insert(:user, email: email, password: "password123")

      assert {:error, :invalid_credentials} = Accounts.authenticate_user(email, "wrong_password")
    end
  end
end
