defmodule OdysseyWeb.API.V1.UserController do
  use OdysseyWeb, :controller

  alias Odyssey.Accounts
  alias Odyssey.Auth.{JWT, LoginToken}

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
end
