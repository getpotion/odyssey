defmodule Odyssey.Accounts do
  @moduledoc """
  The Accounts context for Odyssey, handling user registration, verification, and related logic.
  """
  alias Odyssey.Accounts.User
  alias Odyssey.Repo
  import Ecto.Query, warn: false
  alias Odyssey.Accounts.Behaviour, as: AccountsBehaviour

  @behaviour AccountsBehaviour

  defp email_adapter do
    Application.get_env(:odyssey, :email_adapter, Odyssey.Email)
  end

  def register_user(attrs \\ %{}) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, user} ->
        send_verification_email(user)
        {:ok, user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def get_user_by_user_id(user_id) do
    case Repo.get_by(User, user_id: user_id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def get_user_by_email(email) do
    Repo.get_by(User, email: email)
  end

  def get_user_by_verification_token(token) do
    Repo.get_by(User, verification_token: token)
  end

  def verify_email(token) do
    user = get_user_by_verification_token(token)

    cond do
      is_nil(user) ->
        {:error, :invalid_token}

      is_nil(user.verification_token_expires_at) ->
        {:error, :invalid_token}

      true ->
        expires_at =
          case user.verification_token_expires_at do
            %NaiveDateTime{} = naive -> DateTime.from_naive!(naive, "Etc/UTC")
            %DateTime{} = dt -> dt
          end

        if DateTime.compare(expires_at, DateTime.utc_now()) == :lt do
          {:error, :expired_token}
        else
          now = DateTime.utc_now() |> DateTime.to_naive()

          user
          |> User.update_changeset(%{
            email_verified_at: now,
            verification_token: nil,
            verification_token_expires_at: ~N[1970-01-01 00:00:00]
          })
          |> Repo.update()
        end
    end
  end

  def authenticate_user(email, password) do
    user = Repo.get_by(User, email: email)

    cond do
      is_nil(user) ->
        Bcrypt.no_user_verify()
        {:error, :invalid_credentials}

      Bcrypt.verify_pass(password, user.password_hash) ->
        {:ok, user}

      true ->
        {:error, :invalid_credentials}
    end
  end

  defp send_verification_email(user) do
    verification_url =
      "http://#{Application.get_env(:odyssey, OdysseyWeb)[:domain]}/v1/api/users/verify/#{user.verification_token}"

    email_adapter().send_verification_email(user.email, verification_url)
  end
end
