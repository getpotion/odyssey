defmodule Odyssey.Accounts.TwoFactor do
  @moduledoc """
  Handles two-factor authentication operations.
  """

  alias Odyssey.Accounts.User
  alias Odyssey.Repo

  @behaviour Odyssey.Accounts.TwoFactor.Behaviour

  @doc """
  Generates a new TOTP secret and QR code for 2FA setup.
  """
  def generate_totp_secret do
    secret = :crypto.strong_rand_bytes(20) |> Base.encode32(padding: false)
    {secret, generate_qr_code(secret)}
  end

  @doc """
  Verifies a TOTP code against a secret.
  """
  def verify_totp_code(secret, code) do
    code_str = if is_integer(code), do: Integer.to_string(code), else: to_string(code)
    :pot.valid_totp(code_str, secret)
  end

  @doc """
  Generates recovery codes for a user.
  """
  def generate_recovery_codes do
    Enum.map(1..8, fn _ ->
      :crypto.strong_rand_bytes(5)
      |> Base.encode16()
      |> binary_part(0, 10)
    end)
  end

  @doc """
  Enables 2FA for a user.
  """
  def enable_2fa(user, secret, recovery_codes) do
    user
    |> User.two_factor_changeset(%{
      two_factor_enabled: true,
      two_factor_secret: secret,
      recovery_codes: recovery_codes
    })
    |> Repo.update()
  end

  @doc """
  Verifies a recovery code for a user.
  """
  def verify_recovery_code(user, code) do
    if code in user.recovery_codes do
      # Remove the used recovery code
      new_codes = Enum.reject(user.recovery_codes, &(&1 == code))
      {:ok, _user} = Repo.update(Ecto.Changeset.change(user, recovery_codes: new_codes))
      :ok
    else
      :error
    end
  end

  defp generate_qr_code(secret) do
    # Generate QR code URL for authenticator apps
    issuer = "Odyssey"
    # This should be replaced with the actual user's email
    account = "user@example.com"
    "otpauth://totp/#{issuer}:#{account}?secret=#{secret}&issuer=#{issuer}"
  end
end
