import Mox

defmodule OdysseyWeb.User2FAControllerTest do
  use OdysseyWeb.ConnCase
  alias Odyssey.Accounts
  alias Odyssey.Accounts.TwoFactor
  alias Odyssey.Accounts.TwoFactorMock
  alias Odyssey.EmailMock

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    Application.put_env(:odyssey, :two_factor_impl, Odyssey.Accounts.TwoFactorMock)

    Mox.stub(TwoFactorMock, :generate_totp_secret, fn ->
      {"JBSWY3DPEHPK3PXP",
       "otpauth://totp/Odyssey:user@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Odyssey"}
    end)

    Mox.stub(TwoFactorMock, :generate_recovery_codes, fn ->
      ["CODE1", "CODE2"]
    end)

    Mox.stub(TwoFactorMock, :verify_totp_code, fn _secret, code ->
      code == :pot.totp("JBSWY3DPEHPK3PXP")
    end)

    Mox.stub(TwoFactorMock, :enable_2fa, fn user, _secret, _codes ->
      {:ok, user}
    end)

    Mox.stub(EmailMock, :send_verification_email, fn _email, _url -> :ok end)

    on_exit(fn ->
      Application.delete_env(:odyssey, :two_factor_impl)
    end)

    password = Faker.String.base64(12)
    {:ok, user} =
      Accounts.register_user(%{
        user_id: Faker.UUID.v4(),
        email: Faker.Internet.email(),
        password: password
      })

    {:ok, user} = Accounts.verify_email(user.verification_token)
    %{user: user}
  end

  defp login_user(conn, user) do
    conn
    |> init_test_session(%{user_id: user.user_id})
    |> assign(:current_user, user)
  end

  test "renders 2FA setup page and sets session", %{user: user} do
    conn = build_conn() |> login_user(user)
    conn = get(conn, "/users/2fa/setup")
    assert html_response(conn, 200)
    assert get_session(conn, :two_factor_secret)
    assert get_session(conn, :recovery_codes)
  end

  test "renders 2FA verify page", %{user: user} do
    conn = build_conn() |> login_user(user)
    conn = get(conn, "/users/2fa")
    assert html_response(conn, 200)
  end

  test "successful 2FA setup", %{user: user} do
    conn = build_conn() |> login_user(user)
    conn = get(conn, "/users/2fa/setup")
    secret = get_session(conn, :two_factor_secret)
    conn = recycle(conn) |> login_user(user)
    conn = put_session(conn, :two_factor_secret, secret)
    conn = put_session(conn, :recovery_codes, ["CODE1", "CODE2"])
    conn = post(conn, "/users/2fa/setup/verify", %{code: :pot.totp(secret)})
    assert redirected_to(conn) == "/"
    conn = get(conn, "/")
    assert Phoenix.Flash.get(conn.assigns.flash, :info) == "2FA enabled successfully"
  end

  test "failed 2FA setup with invalid code", %{user: user} do
    conn = build_conn() |> login_user(user)
    conn = get(conn, "/users/2fa/setup")
    secret = get_session(conn, :two_factor_secret)
    conn = recycle(conn) |> login_user(user)
    conn = put_session(conn, :two_factor_secret, secret)
    conn = put_session(conn, :recovery_codes, ["CODE1", "CODE2"])
    conn = post(conn, "/users/2fa/setup/verify", %{code: "000000"})
    assert redirected_to(conn) == "/users/2fa/setup"
    conn = get(conn, "/users/2fa/setup")
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid 2FA code"
  end

  test "verify_code with valid code redirects to poll", %{user: user} do
    # Use a valid base32-encoded secret
    secret = "JBSWY3DPEHPK3PXP"
    {:ok, user} = TwoFactor.enable_2fa(user, secret, ["CODE1"])
    conn = build_conn() |> login_user(user)
    conn = put_session(conn, :login_token_id, "token-123")
    user = %{user | two_factor_secret: secret}
    conn = assign(conn, :current_user, user)
    code = :pot.totp(secret)
    conn = post(conn, "/users/2fa/verify", %{code: code})
    assert redirected_to(conn) == "/v1/api/login/poll/token-123"
  end

  test "verify_code with invalid code flashes error", %{user: user} do
    secret = "JBSWY3DPEHPK3PXP"
    {:ok, user} = TwoFactor.enable_2fa(user, secret, ["CODE1"])
    conn = build_conn() |> login_user(user)
    conn = put_session(conn, :login_token_id, "token-123")
    user = %{user | two_factor_secret: secret}
    conn = assign(conn, :current_user, user)
    conn = post(conn, "/users/2fa/verify", %{code: "000000"})
    assert redirected_to(conn) == "/users/2fa"
    conn = get(conn, "/users/2fa")
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid 2FA code"
  end

  test "verify_code with user not found flashes error", %{user: user} do
    conn = build_conn() |> login_user(%{user | user_id: "nonexistent"})
    conn = put_session(conn, :login_token_id, "token-123")
    conn = post(conn, "/users/2fa/verify", %{code: "000000"})
    assert redirected_to(conn) == "/users/login"
  end

  test "setup verify with user not found flashes error and halts", %{user: user} do
    # First get the secret with a valid user
    conn = build_conn() |> login_user(user)
    conn = get(conn, "/users/2fa/setup")
    secret = get_session(conn, :two_factor_secret)

    # Then try to verify with a non-existent user
    conn = build_conn() |> login_user(%{user | user_id: "nonexistent"})
    conn = put_session(conn, :two_factor_secret, secret)
    conn = put_session(conn, :recovery_codes, ["CODE1", "CODE2"])
    conn = post(conn, "/users/2fa/setup/verify", %{code: :pot.totp(secret)})
    assert redirected_to(conn) == "/users/login"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Please login to continue"
    assert conn.halted
  end

  test "failed_to_enable_2fa branch is hit", %{user: user} do
    TwoFactorMock
    |> expect(:verify_totp_code, fn _secret, _code -> true end)
    |> expect(:enable_2fa, fn _user, _secret, _codes ->
      {:error, Ecto.Changeset.change(%Odyssey.Accounts.User{}, %{two_factor_enabled: nil})}
    end)

    conn = build_conn() |> login_user(user)
    conn = get(conn, "/users/2fa/setup")
    secret = get_session(conn, :two_factor_secret)
    conn = recycle(conn) |> login_user(user)
    conn = put_session(conn, :two_factor_secret, secret)
    conn = put_session(conn, :recovery_codes, ["CODE1", "CODE2"])
    code = :pot.totp(secret)
    conn = post(conn, "/users/2fa/setup/verify", %{code: code})
    assert redirected_to(conn) == "/users/2fa/setup"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Failed to enable 2FA"
  end

  test "setup verify with missing two_factor_secret behaves as invalid code", %{user: user} do
    conn = build_conn() |> login_user(user)
    # Do not set :two_factor_secret
    conn = put_session(conn, :recovery_codes, ["CODE1", "CODE2"])
    conn = post(conn, "/users/2fa/setup/verify", %{code: "000000"})
    assert redirected_to(conn) == "/users/2fa/setup"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid 2FA code"
    assert conn.halted
  end

  test "setup verify with missing recovery_codes still enables 2FA if code is valid", %{
    user: user
  } do
    {secret, _qr_code} = TwoFactorMock.generate_totp_secret()
    conn = build_conn() |> login_user(user)
    conn = put_session(conn, :two_factor_secret, secret)
    # Do not set :recovery_codes
    valid_code = :pot.totp(secret)
    conn = post(conn, "/users/2fa/setup/verify", %{code: valid_code})
    assert redirected_to(conn) == "/"
    assert Phoenix.Flash.get(conn.assigns.flash, :info) == "2FA enabled successfully"
  end

  test "verify_code with missing login_token_id redirects to poll root", %{user: user} do
    secret = "JBSWY3DPEHPK3PXP"
    {:ok, user} = TwoFactor.enable_2fa(user, secret, ["CODE1"])
    user = %{user | two_factor_secret: secret}
    conn = build_conn() |> login_user(user)
    # Do not set :login_token_id
    valid_code = :pot.totp(secret)
    conn = post(conn, "/users/2fa/verify", %{code: valid_code})
    assert redirected_to(conn) == "/v1/api/login/poll"
  end

  test "verify_code with nil two_factor_secret behaves as invalid code", %{user: user} do
    user = %{user | two_factor_secret: nil}
    conn = build_conn() |> login_user(user)
    conn = put_session(conn, :login_token_id, "sometoken")
    conn = post(conn, "/users/2fa/verify", %{code: "000000"})
    assert redirected_to(conn) == "/users/2fa"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) == "Invalid 2FA code"
  end
end
