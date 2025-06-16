defmodule OdysseyWeb.User.Controller do
  @moduledoc """
  Handles user registration and email verification operations.
  Provides endpoints for user registration and email verification token validation.
  """

  use OdysseyWeb, :controller

  defp accounts, do: Application.get_env(:odyssey, :accounts, Odyssey.Accounts)

  def register(conn, %{"user_id" => user_id, "email" => email, "password" => password}) do
    case accounts().register_user(%{user_id: user_id, email: email, password: password}) do
      {:ok, _user} ->
        conn
        |> put_status(:created)
        |> json(%{message: "User registered. Please verify your email."})

      {:error, %Ecto.Changeset{errors: errors}} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: format_errors(errors)})
    end
  end

  def verify(conn, %{"token" => token}) do
    case accounts().verify_email(token) do
      {:ok, _user} ->
        conn
        |> put_status(:ok)
        |> json(%{message: "Account verified!"})

      {:error, :invalid_token} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Invalid or expired token"})

      {:error, :expired_token} ->
        conn
        |> put_status(:gone)
        |> json(%{error: "Verification token has expired"})
    end
  end

  defp format_errors(errors) do
    errors
    |> Enum.map(fn {field, {message, _}} -> "#{field} #{message}" end)
    |> List.first()
  end
end
