defmodule AuthManager.Phoenix do
  @moduledoc """
  Funciones para integrar AuthManager con Phoenix.

  Función para utilizar en un controller de Phoenix para requerir autenticación.

  ## Ejemplo

  ```elixir
  defmodule MyAppWeb.UserController do
    use MyAppWeb, :controller
    use AuthManager.Phoenix, :controller

    plug :require_authenticated_user when action in [:index, :show]

    def index(conn, _params) do
      # Solo usuarios autenticados pueden acceder aquí
      render(conn, "index.html")
    end
  end
  ```
  """
  defmacro __using__(:controller) do
    quote do
      import AuthManager.Accounts.AuthenticationPlug
      import AuthManager.Core.Middleware

      @doc """
      Plug para requerir que un usuario esté autenticado.
      """
      def require_authenticated_user(conn, _opts) do
        if conn.assigns[:current_user] do
          conn
        else
          conn
          |> put_status(401)
          |> Phoenix.Controller.put_flash(:error, "Debe iniciar sesión para acceder a esta página.")
          |> Phoenix.Controller.redirect(to: "/login")
          |> halt()
        end
      end

      @doc """
      Plug para requerir que no haya un usuario autenticado.
      """
      def require_unauthenticated_user(conn, _opts) do
        if conn.assigns[:current_user] do
          conn
          |> put_status(303)
          |> Phoenix.Controller.put_flash(:error, "Ya ha iniciado sesión.")
          |> Phoenix.Controller.redirect(to: "/")
          |> halt()
        else
          conn
        end
      end
    end
  end

  @doc """
  Función para utilizar en un router de Phoenix para añadir rutas de autenticación.

  ## Ejemplo

  ```elixir
  defmodule MyAppWeb.Router do
    use MyAppWeb, :router
    use AuthManager.Phoenix, :router

    # ... otras configuraciones

    # Añade rutas de autenticación estándar (login, logout, registro, etc.)
    auth_routes()
  end
  ```
  """
  defmacro __using__(:router) do
    quote do
      import AuthManager.Phoenix

      @doc """
      Macro para añadir un pipeline de autenticación a un router de Phoenix.
      """
      defmacro auth_pipeline do
        quote do
          pipeline :auth do
            plug AuthManager.Accounts.AuthPipeline
          end
        end
      end

      @doc """
      Macro para añadir rutas de autenticación estándar a un router de Phoenix.
      """
      defmacro auth_routes(opts \\ []) do
        quote do
          scope "/auth", unquote(opts[:scope] || AuthManager.Web) do
            pipe_through [:browser, :redirect_if_authenticated]

            get "/login", SessionController, :new
            post "/login", SessionController, :create
            get "/register", RegistrationController, :new
            post "/register", RegistrationController, :create
          end

          scope "/auth", unquote(opts[:scope] || AuthManager.Web) do
            pipe_through [:browser, :require_authenticated_user]

            delete "/logout", SessionController, :delete
          end
        end
      end

      @doc """
      Macro para añadir rutas de API de autenticación estándar a un router de Phoenix.
      """
      defmacro auth_api_routes(opts \\ []) do
        quote do
          scope "/api/auth", unquote(opts[:scope] || AuthManager.Web.API) do
            pipe_through [:api]

            post "/login", SessionController, :create
            post "/register", RegistrationController, :create
            post "/refresh_token", TokenController, :refresh
          end

          scope "/api/auth", unquote(opts[:scope] || AuthManager.Web.API) do
            pipe_through [:api, :api_auth]

            delete "/logout", SessionController, :delete
            get "/me", UserController, :me
          end
        end
      end
    end
  end

  @doc """
  Función para utilizar en un view de Phoenix para añadir helpers de autenticación.

  ## Ejemplo

  ```elixir
  defmodule MyAppWeb.LayoutView do
    use MyAppWeb, :view
    use AuthManager.Phoenix, :view

    # Ahora puede usar funciones como `logged_in?` y `current_user` en sus templates
  end
  ```
  """
  defmacro __using__(:view) do
    quote do
      @doc """
      Comprueba si hay un usuario autenticado en la conexión.
      """
      def logged_in?(conn) do
        conn.assigns[:current_user] != nil
      end

      @doc """
      Obtiene el usuario autenticado actual de la conexión.
      """
      def current_user(conn) do
        conn.assigns[:current_user]
      end

      @doc """
      Comprueba si el usuario actual tiene un permiso específico.
      """
      def has_permission?(conn, permission) do
        user = current_user(conn)
        user && AuthManager.can?(user, permission)
      end

      @doc """
      Comprueba si el usuario actual tiene un rol específico.
      """
      def has_role?(conn, role) do
        user = current_user(conn)
        user && AuthManager.has_role?(user, role)
      end
    end
  end
end
