defmodule OdysseyWeb.User2FAController do
  use OdysseyWeb, :controller

  alias Odyssey.Accounts

  defp two_factor_impl do
    Application.get_env(:odyssey, :two_factor_impl, Odyssey.Accounts.TwoFactor)
  end

  def setup(conn, _params) do
    {secret, qr_code} = two_factor_impl().generate_totp_secret()
    recovery_codes = two_factor_impl().generate_recovery_codes()

    conn
    |> put_session(:two_factor_secret, secret)
    |> put_session(:recovery_codes, recovery_codes)
    |> render(:setup, qr_code: qr_code, recovery_codes: recovery_codes)
  end

  def verify_setup(conn, %{"code" => code}) do
    secret = get_session(conn, :two_factor_secret)
    recovery_codes = get_session(conn, :recovery_codes)

    if two_factor_impl().verify_totp_code(secret, code) do
      do_verify_setup(conn, secret, recovery_codes)
    else
      invalid_2fa_code(conn)
    end
  end

  defp do_verify_setup(conn, secret, recovery_codes) do
    case Accounts.get_user_by_user_id(conn.assigns.current_user.user_id) do
      {:error, _reason} ->
        user_not_found(conn)

      {:ok, user} ->
        case two_factor_impl().enable_2fa(user, secret, recovery_codes) do
          {:ok, _user} ->
            conn
            |> put_flash(:info, "2FA enabled successfully")
            |> redirect(to: ~p"/")

          {:error, _changeset} ->
            failed_to_enable_2fa(conn)
        end
    end
  end

  defp invalid_2fa_code(conn) do
    conn
    |> put_flash(:error, "Invalid 2FA code")
    |> redirect(to: ~p"/users/2fa/setup")
    |> halt()
  end

  defp user_not_found(conn) do
    conn
    |> put_flash(:error, "User not found")
    |> redirect(to: ~p"/users/2fa/setup")
    |> halt()
  end

  defp failed_to_enable_2fa(conn) do
    conn
    |> put_flash(:error, "Failed to enable 2FA")
    |> redirect(to: ~p"/users/2fa/setup")
    |> halt()
  end

  def verify(conn, _params) do
    render(conn, :verify)
  end

  def verify_code(conn, %{"code" => code}) do
    token_id = get_session(conn, :login_token_id)

    with {:ok, user} <- get_current_user(conn),
         :ok <- verify_2fa_enabled(user),
         :ok <- verify_2fa_code(user, code) do
      redirect_path =
        if token_id do
          ~p"/v1/api/login/poll/#{token_id}"
        else
          ~p"/v1/api/login/poll"
        end

      conn |> redirect(to: redirect_path)
    else
      {:error, :not_authenticated} ->
        conn
        |> put_flash(:error, "Not authenticated")
        |> redirect(to: ~p"/users/2fa")
      {:error, :not_enabled} ->
        conn
        |> put_flash(:error, "2FA is not enabled")
        |> redirect(to: ~p"/users/2fa")
      {:error, :invalid_code} ->
        conn
        |> put_flash(:error, "Invalid 2FA code")
        |> redirect(to: ~p"/users/2fa")
    end
  end

  defp get_current_user(conn) do
    case Accounts.get_user_by_user_id(conn.assigns.current_user.user_id) do
      {:ok, user} -> {:ok, user}
      {:error, _reason} -> {:error, :not_authenticated}
    end
  end

  defp verify_2fa_enabled(user) do
    if user.two_factor_enabled && user.two_factor_secret do
      :ok
    else
      {:error, :invalid_code}
    end
  end

  defp verify_2fa_code(user, code) do
    if two_factor_impl().verify_totp_code(user.two_factor_secret, code) do
      :ok
    else
      {:error, :invalid_code}
    end
  end
end
