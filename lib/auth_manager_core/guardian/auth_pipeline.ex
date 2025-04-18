defmodule AuthManagerCore.Guardian.AuthPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :auth_manager_core,
    error_handler: AuthManagerCore.Guardian.ErrorHandler,
    module: AuthManagerCore.Guardian

  # Si hay un token, lo validamos y lo requerimos
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
