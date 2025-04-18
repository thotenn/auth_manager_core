defmodule AuthManager.Accounts.AuthErrorHandler do
  @moduledoc """
  Manejador de errores para problemas de autenticación.
  """
  import Plug.Conn
  alias AuthManager.Core.Config

  @doc """
  Maneja errores de autenticación. Puede ser personalizado por la aplicación host.
  """
  def auth_error(conn, {type, _reason}, _opts) do
    error_view = Config.error_view() || Phoenix.Controller.view_module(conn)

    conn
    |> put_status(401)
    |> Phoenix.Controller.put_view(error_view)
    |> Phoenix.Controller.render("401.json", %{error: format_error(type)})
    |> halt()
  end

  # Formatea los mensajes de error para mostrar mensajes más amigables
  defp format_error(:unauthenticated), do: "No autenticado"
  defp format_error(:invalid_token), do: "Token inválido"
  defp format_error(:expired), do: "Token expirado"
  defp format_error(:token_type_not_found), do: "Tipo de token no encontrado"
  defp format_error(:token_verification_failed), do: "Verificación de token fallida"
  defp format_error(other), do: "Error de autenticación: #{inspect(other)}"
end
