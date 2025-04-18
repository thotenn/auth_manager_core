defmodule AuthManagerCore.Guardian.Pipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :auth_manager_core,
    error_handler: AuthManagerCore.Guardian.ErrorHandler,
    module: AuthManagerCore.Guardian

  # Si hay un token, lo validamos y cargamos
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
