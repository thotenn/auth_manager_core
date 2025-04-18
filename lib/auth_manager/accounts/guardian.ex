defmodule AuthManager.Accounts.Guardian do
  @moduledoc """
  Implementación de Guardian para la autenticación basada en JWT.
  """
  use Guardian, otp_app: :auth_manager_core

  alias AuthManager.Accounts.UserService

  @doc """
  Función utilizada para extraer el identificador del recurso de un subject.
  """
  def subject_for_token(user, _claims) do
    sub = to_string(user.id)
    {:ok, sub}
  end

  @doc """
  Función utilizada para cargar el recurso a partir del subject.
  """
  def resource_from_claims(claims) do
    id = claims["sub"]

    case UserService.get_user(id) do
      nil -> {:error, :resource_not_found}
      user -> {:ok, user}
    end
  end

  @doc """
  Función para crear tokens de acceso para un usuario.
  """
  def create_access_token(user) do
    {:ok, token, _claims} = encode_and_sign(user, %{}, token_type: "access")
    token
  end

  @doc """
  Función para crear tokens de refresco para un usuario.
  """
  def create_refresh_token(user) do
    {:ok, token, _claims} = encode_and_sign(user, %{}, token_type: "refresh", ttl: {30, :days})
    token
  end

  @doc """
  Función para intercambiar un token de refresco por un nuevo token de acceso.
  """
  def exchange_refresh_token(refresh_token) do
    case decode_and_verify(refresh_token, %{"typ" => "refresh"}) do
      {:ok, claims} ->
        case resource_from_claims(claims) do
          {:ok, user} ->
            {:ok, create_access_token(user), create_refresh_token(user)}
          error ->
            error
        end
      error ->
        error
    end
  end

  @doc """
  Función para verificar y obtener el usuario a partir de un token.
  """
  def get_user_from_token(token) do
    case decode_and_verify(token) do
      {:ok, claims} -> resource_from_claims(claims)
      error -> error
    end
  end
end
