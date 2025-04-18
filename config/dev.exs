import Config

# Reducir el costo del hash en desarrollo para mayor velocidad
config :bcrypt_elixir, log_rounds: 4
