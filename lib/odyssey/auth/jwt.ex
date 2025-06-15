defmodule Odyssey.Auth.JWT do
  @moduledoc """
  Handles JWT token operations.
  """

  use Joken.Config

  def token_config do
    default_claims(
      iss: "odyssey",
      aud: "odyssey",
      # 24 hours
      default_exp: 24 * 60 * 60
    )
  end

  @doc """
  Generates a JWT token for a user.
  """
  def generate_token(user) do
    extra_claims = %{
      "user_id" => user.user_id,
      "email" => user.email
    }

    {:ok, token, _claims} = generate_and_sign(extra_claims, signer())
    token
  end

  @doc """
  Verifies a JWT token.
  """
  def verify_token(token) do
    case verify_and_validate(token, signer()) do
      {:ok, claims} -> {:ok, claims}
      {:error, reason} -> {:error, reason}
    end
  end

  defp signer do
    Joken.Signer.create("HS256", Application.get_env(:joken, :default_signer))
  end
end
