defmodule AuthManagerCore.Guardian do
  use Guardian, otp_app: :auth_manager_core

  alias AuthManagerCore.Auth

  def subject_for_token(user, _claims) do
    {:ok, to_string(user.id)}
  end

  def resource_from_claims(%{"sub" => id}) do
    user = Auth.get_user(id)
    {:ok, user}
  rescue
    Ecto.NoResultsError -> {:error, :resource_not_found}
  end
end
