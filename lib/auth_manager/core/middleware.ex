defmodule AuthManager.Core.Middleware do
  @moduledoc """
  Proporciona middlewares para Phoenix para verificar permisos y roles.
  """
  import Plug.Conn
  import Phoenix.Controller
  alias AuthManager.Core.Controller

  @doc """
  Crea un plug que verifica si un usuario tiene un permiso específico.

  ## Opciones

  * `:permission` - El permiso requerido (obligatorio)
  * `:assign_key` - La clave para almacenar el resultado en conn.assigns (por defecto: :authorized)
  * `:handler` - Función para manejar usuarios no autorizados
  * `:error_message` - Mensaje de error para usuarios no autorizados
  * `:error_view` - Vista de error para usuarios no autorizados
  * `:error_template` - Plantilla de error para usuarios no autorizados
  """
  def require_permission(opts) do
    permission = Keyword.fetch!(opts, :permission)
    assign_key = Keyword.get(opts, :assign_key, :authorized)
    handler = Keyword.get(opts, :handler)
    error_message = Keyword.get(opts, :error_message, "No tienes permiso para acceder a este recurso")
    error_view = Keyword.get(opts, :error_view, "error.json")
    error_template = Keyword.get(opts, :error_template, "403.json")

    fn conn, _params ->
      current_user = conn.assigns[:current_user]

      if current_user && Controller.can?(current_user, permission) do
        assign(conn, assign_key, true)
      else
        conn = assign(conn, assign_key, false)

        if handler do
          handler.(conn)
        else
          conn
          |> put_status(:forbidden)
          |> put_view(error_view)
          |> render(error_template, %{error: error_message})
          |> halt()
        end
      end
    end
  end

  @doc """
  Crea un plug que verifica si un usuario tiene un rol específico.

  ## Opciones

  * `:role` - El rol requerido (obligatorio)
  * `:assign_key` - La clave para almacenar el resultado en conn.assigns (por defecto: :authorized)
  * `:handler` - Función para manejar usuarios no autorizados
  * `:error_message` - Mensaje de error para usuarios no autorizados
  * `:error_view` - Vista de error para usuarios no autorizados
  * `:error_template` - Plantilla de error para usuarios no autorizados
  """
  def require_role(opts) do
    role = Keyword.fetch!(opts, :role)
    assign_key = Keyword.get(opts, :assign_key, :authorized)
    handler = Keyword.get(opts, :handler)
    error_message = Keyword.get(opts, :error_message, "No tienes el rol necesario para acceder a este recurso")
    error_view = Keyword.get(opts, :error_view, "error.json")
    error_template = Keyword.get(opts, :error_template, "403.json")

    fn conn, _params ->
      current_user = conn.assigns[:current_user]

      if current_user && Controller.has_role?(current_user, role) do
        assign(conn, assign_key, true)
      else
        conn = assign(conn, assign_key, false)

        if handler do
          handler.(conn)
        else
          conn
          |> put_status(:forbidden)
          |> put_view(error_view)
          |> render(error_template, %{error: error_message})
          |> halt()
        end
      end
    end
  end

  @doc """
  Crea un plug que verifica una condición personalizada utilizando can_by?.

  ## Ejemplos

  ```elixir
  # Verificar si un usuario tiene un permiso
  pipe_through [:browser, AuthManager.Core.Middleware.authorize(permission: "admin:read")]

  # Verificar si un usuario tiene un rol
  pipe_through [:browser, AuthManager.Core.Middleware.authorize(role: "admin")]

  # Verificar si un rol tiene un permiso (usando el rol del usuario actual)
  pipe_through [:browser, AuthManager.Core.Middleware.authorize(permission: "admin:read", use_current_user_role: true)]
  ```
  """
  def authorize(opts) do
    permission = Keyword.get(opts, :permission)
    role = Keyword.get(opts, :role)
    use_current_user_role = Keyword.get(opts, :use_current_user_role, false)
    assign_key = Keyword.get(opts, :assign_key, :authorized)
    handler = Keyword.get(opts, :handler)
    error_message = Keyword.get(opts, :error_message, "No estás autorizado para acceder a este recurso")
    error_view = Keyword.get(opts, :error_view, "error.json")
    error_template = Keyword.get(opts, :error_template, "403.json")

    fn conn, _params ->
      current_user = conn.assigns[:current_user]

      authorized = cond do
        is_nil(current_user) ->
          false

        permission && role && use_current_user_role ->
          # Verificar si el rol del usuario tiene un permiso específico
          user_roles = Controller.get_user_roles(current_user)

          Enum.any?(user_roles, fn user_role ->
            Controller.can_by?(role: user_role, permission: permission)
          end)

        permission && !role ->
          # Verificar si el usuario tiene un permiso específico
          Controller.can?(current_user, permission)

        !permission && role ->
          # Verificar si el usuario tiene un rol específico
          Controller.has_role?(current_user, role)

        true ->
          raise ArgumentError, "Configuración inválida para authorize/1"
      end

      if authorized do
        assign(conn, assign_key, true)
      else
        conn = assign(conn, assign_key, false)

        if handler do
          handler.(conn)
        else
          conn
          |> put_status(:forbidden)
          |> put_view(error_view)
          |> render(error_template, %{error: error_message})
          |> halt()
        end
      end
    end
  end
end
