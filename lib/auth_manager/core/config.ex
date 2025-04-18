defmodule AuthManager.Core.Config do
  @moduledoc """
  Módulo para gestionar la configuración de AuthManager.
  """

  @doc """
  Obtiene una configuración específica.
  """
  def get(key, default \\ nil) do
    Application.get_env(:auth_manager, key, default)
  end

  @doc """
  Obtiene el repositorio configurado para la aplicación.
  """
  def repo do
    get(:repo) ||
      raise "Por favor, configura :auth_manager, :repo en tus archivos de configuración"
  end

  @doc """
  Configura el repositorio para la aplicación en tiempo de ejecución.
  Útil para pruebas o configuración dinámica.
  """
  def configure_repo(repo) do
    Application.put_env(:auth_manager, :repo, repo)
  end

  @doc """
  Configura el endpoint Phoenix para la aplicación en tiempo de ejecución.
  """
  def configure_endpoint(endpoint) do
    Application.put_env(:auth_manager, :endpoint, endpoint)
  end

  @doc """
  Obtiene el endpoint configurado para la aplicación.
  """
  def endpoint do
    get(:endpoint)
  end

  @doc """
  Configura los módulos de vistas y plantillas para errores de autenticación/autorización.
  """
  def configure_error_views(error_view, error_template) do
    Application.put_env(:auth_manager, :error_view, error_view)
    Application.put_env(:auth_manager, :error_template, error_template)
  end

  @doc """
  Obtiene la vista de error configurada.
  """
  def error_view do
    get(:error_view, Application.get_env(:phoenix, :error_view))
  end

  @doc """
  Obtiene la plantilla de error configurada.
  """
  def error_template do
    get(:error_template, "403.html")
  end

  @doc """
  Configura el manejador de sesión.
  """
  def configure_session_handler(handler) do
    Application.put_env(:auth_manager, :session_handler, handler)
  end

  @doc """
  Obtiene el manejador de sesión configurado.
  """
  def session_handler do
    get(:session_handler)
  end
end
