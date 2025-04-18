defmodule AuthManager.Accounts.AuthenticationPlug do
  @moduledoc """
  Plug para autenticación de usuarios mediante JWT tokens.
  """
  import Plug.Conn
  alias AuthManager.Accounts.Guardian

  @doc """
  Inicializa el plug con opciones personalizadas.
  """
  def init(opts), do: opts

  @doc """
  Verifica la autenticación del usuario mediante un token JWT.

  ## Opciones
  * `:header` - El header HTTP donde se encuentra el token (default: "authorization")
  * `:schema` - El esquema de autenticación (default: "Bearer")
  * `:error_handler` - Módulo que maneja los errores de autenticación
  * `:halt_on_error` - Si debe detener la conexión en caso de error (default: true)
  """
  def call(conn, opts) do
    header = Keyword.get(opts, :header, "authorization")
    scheme = Keyword.get(opts, :scheme, "Bearer")
    error_handler = Keyword.get(opts, :error_handler)
    halt_on_error = Keyword.get(opts, :halt_on_error, true)

    with token when is_binary(token) <- extract_token(conn, header, scheme),
         {:ok, user} <- Guardian.get_user_from_token(token) do
      # Usuario autenticado correctamente
      assign(conn, :current_user, user)
    else
      nil ->
        # No se encontró el token
        handle_unauthenticated(conn, error_handler, halt_on_error)

      {:error, reason} ->
        # Error al verificar el token
        handle_authentication_error(conn, error_handler, reason, halt_on_error)
    end
  end

  # Extrae el token del header de autorización
  defp extract_token(conn, header, scheme) do
    case get_req_header(conn, String.downcase(header)) do
      [auth_header] -> extract_token_from_header(auth_header, scheme)
      _ -> nil
    end
  end

  # Extrae el token del formato "Bearer <token>"
  defp extract_token_from_header(auth_header, scheme) do
    regex = ~r/^#{scheme}\s+(.+)$/i

    case Regex.run(regex, auth_header) do
      [_, token] -> token
      _ -> nil
    end
  end

  # Maneja el caso de usuario no autenticado
  defp handle_unauthenticated(conn, nil, false) do
    assign(conn, :current_user, nil)
  end

  defp handle_unauthenticated(conn, nil, true) do
    conn
    |> assign(:current_user, nil)
    |> send_resp(401, "Unauthorized")
    |> halt()
  end

  defp handle_unauthenticated(conn, error_handler, _) do
    error_handler.auth_error(conn, {:unauthenticated, "No token found"}, [])
  end

  # Maneja errores de autenticación
  defp handle_authentication_error(conn, nil, _reason, false) do
    assign(conn, :current_user, nil)
  end

  defp handle_authentication_error(conn, nil, reason, true) do
    conn
    |> assign(:current_user, nil)
    |> send_resp(401, "Unauthorized: #{inspect(reason)}")
    |> halt()
  end

  defp handle_authentication_error(conn, error_handler, reason, _) do
    error_handler.auth_error(conn, {:invalid_token, reason}, [])
  end
end
