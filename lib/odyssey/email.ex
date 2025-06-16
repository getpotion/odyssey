defmodule Odyssey.Email do
  @moduledoc """
  Handles email delivery for Odyssey, including sending verification emails to users.
  """
  use Bamboo.Mailer, otp_app: :odyssey
  import Bamboo.Email
  @behaviour Odyssey.Email.Behaviour

  defp domain do
    # Remove port if present
    (Application.get_env(:odyssey, OdysseyWeb)[:domain] || "localhost")
    |> String.split(":")
    |> List.first()
  end

  def verification_email(email, token) do
    new_email()
    |> to(email)
    |> from("noreply@" <> domain())
    |> subject("Verify your account")
    |> html_body("""
      <h1>Welcome to Odyssey!</h1>
      <p>Please verify your email by clicking the link below:</p>
      <p><a href=\"http://#{domain()}/v1/api/users/verify/#{token}\">Verify Email</a></p>
    """)
    |> text_body("""
      Welcome!
      Please verify your email by visiting:
      http://#{domain()}/v1/api/users/verify/#{token}
    """)
  end

  def two_factor_recovery_email(email, token) do
    new_email()
    |> to(email)
    |> from("noreply@" <> domain())
    |> subject("Reset your 2FA settings")
    |> html_body("""
      <h1>Reset your 2FA settings</h1>
      <p>You requested to reset your 2FA settings. Click the link below to proceed:</p>
      <p><a href=\"http://#{domain()}/v1/api/users/2fa/recovery/#{token}\">Reset 2FA Settings</a></p>
      <p>This link will expire in 1 hour.</p>
      <p>If you didn't request this, please ignore this email.</p>
    """)
    |> text_body("""
      Reset your 2FA settings
      You requested to reset your 2FA settings. Visit the link below to proceed:
      http://#{domain()}/v1/api/users/2fa/recovery/#{token}
      This link will expire in 1 hour.
      If you didn't request this, please ignore this email.
    """)
  end

  @impl true
  def send_verification_email(email, token) do
    if Mix.env() == :test do
      :ok
    else
      email
      |> verification_email(token)
      |> deliver_later()
    end
  end

  @impl true
  def send_2fa_recovery_email(email, token) do
    if Mix.env() == :test do
      :ok
    else
      email
      |> two_factor_recovery_email(token)
      |> deliver_later()
    end
  end
end
