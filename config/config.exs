import Config

# Configuración por defecto para la librería
config :auth_manager,
  repo: nil,  # Se debe configurar en la aplicación host
  endpoint: nil,  # Se debe configurar en la aplicación host
  error_view: nil,  # Se debe configurar en la aplicación host
  error_template: "403.html"

# Configuración para bcrypt (costo de hash)
config :bcrypt_elixir, log_rounds: 12

# Importar configuración específica del entorno
import_config "#{config_env()}.exs"
