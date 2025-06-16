defmodule OdysseyWeb.API.V1.User.Controller do
  @moduledoc """
  Handles user authentication and login operations via the API.
  Provides endpoints for login initialization, polling, 2FA verification, and recovery.
  Manages JWT token generation and login token state.
  """

  use OdysseyWeb, :controller

  alias Odyssey.Accounts
  alias Odyssey.Auth.{JWT, LoginToken}
  alias Odyssey.Email

  def login_init(conn, %{"email" => email, "password" => password}) do
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        token_id = LoginToken.generate_token_id()
        LoginToken.store_token(token_id, user.user_id)

        if user.two_factor_enabled do
          conn
          |> put_status(:ok)
          |> json(%{
            token_id: token_id,
            requires_2fa: true
          })
        else
          token = JWT.generate_token(user)
          LoginToken.update_token_status(token_id, :completed, token)

          conn
          |> put_status(:ok)
          |> json(%{
            token_id: token_id,
            requires_2fa: false
          })
        end

      {:error, _reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{errors: %{detail: "Invalid credentials"}})
    end
  end

  def login_poll(conn, %{"token_id" => token_id}) do
    case LoginToken.get_token(token_id) do
      {:ok, %{status: :completed, token: token}} ->
        conn
        |> put_status(:ok)
        |> json(%{token: token})

      {:ok, %{status: :pending}} ->
        conn
        |> put_status(:not_found)
        |> json(%{errors: %{detail: "Token not ready"}})

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{errors: %{detail: "Token not found"}})
    end
  end

  def login_poll(conn, _params) do
    conn
    |> put_status(:not_found)
    |> json(%{errors: %{detail: "Token not found"}})
  end

  def verify_2fa(conn, %{"token_id" => token_id, "code" => code}) do
    case get_token_and_user(token_id) do
      {:ok, user} -> handle_2fa_verification(conn, token_id, code, user)
      {:error, :token_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{errors: %{detail: "Token not found"}})
      {:error, :user_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{errors: %{detail: "User not found"}})
    end
  end

  defp get_token_and_user(token_id) do
    case LoginToken.get_token(token_id) do
      {:ok, %{user_id: user_id}} ->
        case Accounts.get_user_by_user_id(user_id) do
          {:ok, user} -> {:ok, user}
          {:error, _reason} -> {:error, :user_not_found}
        end
      {:error, :not_found} -> {:error, :token_not_found}
    end
  end

  defp handle_2fa_verification(conn, token_id, code, user) do
    if Accounts.TwoFactor.verify_totp_code(user.two_factor_secret, code) do
      token = JWT.generate_token(user)
      LoginToken.update_token_status(token_id, :completed, token)

      conn
      |> put_status(:ok)
      |> json(%{token: token})
    else
      conn
      |> put_status(:unauthorized)
      |> json(%{errors: %{detail: "Invalid 2FA code"}})
    end
  end

  def recover_2fa(conn, %{"recovery_code" => code}) do
    case get_token_and_user(conn.params["token_id"]) do
      {:ok, user} ->
        case Accounts.validate_recovery_code(user.user_id, code) do
          {:ok, updated_user} ->
            token = JWT.generate_token(updated_user)
            LoginToken.update_token_status(conn.params["token_id"], :completed, token)

            conn
            |> put_status(:ok)
            |> json(%{token: token})

          {:error, :invalid_code} ->
            conn
            |> put_status(:bad_request)
            |> json(%{errors: %{detail: "Invalid or used recovery code"}})
        end

      {:error, :token_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{errors: %{detail: "Token not found"}})

      {:error, :user_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{errors: %{detail: "User not found"}})
    end
  end

  def request_2fa_recovery(conn, %{"email" => email}) do
    case Accounts.get_user_by_email(email) do
      nil ->
        handle_user_not_found(conn)
      user ->
        handle_2fa_recovery_request(conn, user)
    end
  end

  defp handle_user_not_found(conn) do
    conn
    |> put_status(:not_found)
    |> json(%{errors: %{detail: "Account not found"}})
  end

  defp handle_2fa_recovery_request(conn, user) do
    if user.two_factor_enabled do
      create_recovery_request(conn, user)
    else
      handle_2fa_not_enabled(conn)
    end
  end

  defp create_recovery_request(conn, user) do
    case Accounts.create_2fa_recovery_request(user) do
      {:ok, recovery_token} ->
        Email.send_2fa_recovery_email(user.email, recovery_token)

        conn
        |> put_status(:ok)
        |> json(%{message: "Recovery email sent."})

      {:error, _reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{errors: %{detail: "Failed to create recovery request"}})
    end
  end

  defp handle_2fa_not_enabled(conn) do
    conn
    |> put_status(:bad_request)
    |> json(%{errors: %{detail: "2FA is not enabled for this account"}})
  end

  def complete_2fa_recovery(conn, %{"token" => token}) do
    case Accounts.validate_recovery_token(token) do
      {:ok, user} ->
        case Accounts.reset_2fa_setup(user) do
          {:ok, updated_user} ->
            token = JWT.generate_token(updated_user)

            conn
            |> put_status(:ok)
            |> json(%{
              token: token,
              message: "2FA has been disabled. Please set up 2FA again for security."
            })

          {:error, _reason} ->
            conn
            |> put_status(:internal_server_error)
            |> json(%{errors: %{detail: "Failed to reset 2FA setup"}})
        end

      {:error, :invalid_token} ->
        conn
        |> put_status(:bad_request)
        |> json(%{errors: %{detail: "Invalid or expired recovery token"}})
    end
  end
end
