defmodule AuthManagerCore.Repo do
  use Ecto.Repo,
    otp_app: :auth_manager_core,
    adapter: Ecto.Adapters.Postgres
end
