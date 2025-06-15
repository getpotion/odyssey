defmodule Odyssey.Accounts.TwoFactorTest do
  @moduledoc """
  Tests for the TwoFactor module.
  """

  use Odyssey.DataCase

  alias Odyssey.Accounts.TwoFactor
  alias Odyssey.Accounts.User
  alias Odyssey.Factory

  @doc """
  Tests the verify_totp_code/2 function.
  """
  describe "verify_totp_code/2" do
    test "verifies a valid TOTP code" do
      {secret, _} = TwoFactor.generate_totp_secret()
      code = :pot.totp(secret)

      assert TwoFactor.verify_totp_code(secret, code)
    end

    test "handles integer codes" do
      secret = "SIARYWFN76GWTZIRLTTKAZGB7KKBC4PH"
      code = :pot.totp(secret)
      assert TwoFactor.verify_totp_code(secret, to_string(code))
    end

    test "rejects an invalid TOTP code" do
      {secret, _} = TwoFactor.generate_totp_secret()
      refute TwoFactor.verify_totp_code(secret, "000000")
    end
  end

  @doc """
  Tests the generate_recovery_codes/0 function.
  """
  describe "generate_recovery_codes/0" do
    test "generates a list of recovery codes" do
      codes = TwoFactor.generate_recovery_codes()

      assert is_list(codes)
      assert length(codes) == 8
      assert Enum.all?(codes, &is_binary/1)
    end
  end

  @doc """
  Tests the enable_2fa/3 function.
  """
  describe "enable_2fa/3" do
    test "successfully enables 2FA for a user" do
      user = Factory.insert(:user, user_id: Faker.UUID.v4(), email: Faker.Internet.email())
      {secret, _} = TwoFactor.generate_totp_secret()
      recovery_codes = Enum.map(1..8, fn _ -> Faker.String.base64(10) end)

      assert {:ok, updated_user} = TwoFactor.enable_2fa(user, secret, recovery_codes)
      assert updated_user.two_factor_enabled
      assert updated_user.two_factor_secret == secret
      assert updated_user.recovery_codes == recovery_codes
    end

    test "returns error with invalid changeset" do
      user = Factory.insert(:user, user_id: Faker.UUID.v4(), email: Faker.Internet.email())
      # Pass empty secret and codes to force changeset error
      assert {:error, _changeset} = TwoFactor.enable_2fa(user, "", [])
    end
  end

  @doc """
  Tests the verify_recovery_code/2 function.
  """
  describe "verify_recovery_code/2" do
    test "verifies a valid recovery code" do
      codes = [Faker.String.base64(10), Faker.String.base64(10), Faker.String.base64(10)]
      user = Factory.insert(:user, recovery_codes: codes)
      assert :ok = TwoFactor.verify_recovery_code(user, Enum.at(codes, 1))
      # Reload user from DB and check codes
      updated_user = Repo.get(User, user.id)
      assert updated_user.recovery_codes == [Enum.at(codes, 0), Enum.at(codes, 2)]
    end

    test "rejects an invalid recovery code" do
      codes = [Faker.String.base64(10), Faker.String.base64(10)]
      user = Factory.insert(:user, recovery_codes: codes)
      assert :error = TwoFactor.verify_recovery_code(user, "INVALID")
      updated_user = Repo.get(User, user.id)
      assert updated_user.recovery_codes == codes
    end

    test "handles empty recovery codes" do
      user = Factory.insert(:user, recovery_codes: [])
      assert :error = TwoFactor.verify_recovery_code(user, Faker.String.base64(10))
    end
  end
end
