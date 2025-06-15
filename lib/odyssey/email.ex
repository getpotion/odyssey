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

  @impl true
  def send_verification_email(email, token) do
    email
    |> verification_email(token)
    |> deliver_later()
  end
end
