defmodule OdysseyWeb.Auth.Pipeline do
  @moduledoc """
  Pipeline for handling authentication.
  """

  import Plug.Conn
  import Phoenix.Controller

  alias Odyssey.Accounts

  def init(opts), do: opts

  def call(conn, _opts) do
    case get_session(conn, :user_id) do
      nil ->
        conn
        |> put_flash(:error, "Please login to continue")
        |> redirect(to: "/users/login")
        |> halt()

      user_id ->
        case Accounts.get_user_by_user_id(user_id) do
          {:ok, user} ->
            assign(conn, :current_user, user)

          {:error, _reason} ->
            conn
            |> delete_session(:user_id)
            |> put_flash(:error, "Please login to continue")
            |> redirect(to: "/users/login")
            |> halt()
        end
    end
  end
end
