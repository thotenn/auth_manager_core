defmodule AuthManager.Accounts.AuthPipeline do
  @moduledoc """
  Pipeline para la autenticación en aplicaciones Phoenix.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :auth_manager,
    module: AuthManager.Accounts.Guardian,
    error_handler: AuthManager.Accounts.AuthErrorHandler

  # Si no existe un error handler, el plug simplemente asigna nil a current_user

  @doc """
  Plug que verifica y carga el usuario actual a partir del token de autorización.
  """
  plug Guardian.Plug.VerifyHeader, realm: "Bearer"

  @doc """
  Plug que carga el recurso (usuario) basado en el token previamente verificado.
  """
  plug Guardian.Plug.LoadResource, allow_blank: true
end
