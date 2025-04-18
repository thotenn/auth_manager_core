# AuthManager

Una biblioteca completa para gestión de usuarios, roles y permisos en aplicaciones Elixir y Phoenix.

## Características

- Sistema de usuarios con datos personales
- Jerarquía de roles y permisos con herencia
- Autenticación basada en JWT con Guardian
- Middleware para verificación de permisos
- Herramientas utilitarias para strings, mapas, listas, fechas y criptografía
- Fácil integración con aplicaciones Phoenix
- Soporte para Phoenix Router y Controllers
- Rutas de autenticación predefinidas

## Instalación

Agrega `auth_manager` a tus dependencias en `mix.exs`:

```elixir
def deps do
  [
    {:auth_manager, "~> 0.1.0"}
  ]
end
```

## Configuración

### Configuración Básica

Configura tu repositorio Ecto en tu archivo `config/config.exs`:

```elixir
config :auth_manager,
  repo: MyApp.Repo,
  endpoint: MyAppWeb.Endpoint
```

### Configuración de Guardian

Para la autenticación con JWT, configura Guardian:

```elixir
config :auth_manager, AuthManager.Accounts.Guardian,
  issuer: "my_app",
  secret_key: "tu_clave_secreta", # O mejor usar System.get_env("SECRET_KEY_BASE")
  ttl: {60, :minute}
```

### Migraciones

Ejecuta las migraciones:

```bash
mix ecto.gen.migration copy_auth_manager_migrations
```

En el archivo de migración generado, copia las migraciones de AuthManager:

```elixir
defmodule MyApp.Repo.Migrations.CopyAuthManagerMigrations do
  use Ecto.Migration

  def up do
    AuthManager.Migrations.CreateUsers.up()
    AuthManager.Migrations.CreateRoles.up()
    AuthManager.Migrations.CreatePermissions.up()
    AuthManager.Migrations.CreateUserRoles.up()
    AuthManager.Migrations.CreateUserPermissions.up()
    AuthManager.Migrations.CreateRolePermissions.up()
    AuthManager.Migrations.CreateRoleRoles.up()
  end

  def down do
    AuthManager.Migrations.CreateRoleRoles.down()
    AuthManager.Migrations.CreateRolePermissions.down()
    AuthManager.Migrations.CreateUserPermissions.down()
    AuthManager.Migrations.CreateUserRoles.down()
    AuthManager.Migrations.CreatePermissions.down()
    AuthManager.Migrations.CreateRoles.down()
    AuthManager.Migrations.CreateUsers.down()
  end
end
```

Luego ejecuta:

```bash
mix ecto.migrate
```

### Datos iniciales

Para crear los roles y permisos básicos:

```elixir
# En tu archivo de semillas (seeds.exs)
AuthManager.Core.Seeds.ensure_seeds_exist()
```

## Uso básico

### Crear y gestionar usuarios

```elixir
# Crear un nuevo usuario
{:ok, user} = AuthManager.create_user(%{
  first_name: "Juan",
  last_name: "Pérez",
  username: "juanperez",
  email: "juan@example.com",
  password: "secretpassword"
})

# Crear un rol
{:ok, admin_role} = AuthManager.create_role(%{
  name: "Administrador",
  description: "Acceso completo al sistema"
})

# Crear un permiso
{:ok, manage_users} = AuthManager.create_permission(%{
  name: "Gestionar usuarios",
  slug: "manage_users",
  description: "Permite gestionar usuarios del sistema"
})

# Asignar un rol a un usuario
{:ok, _} = AuthManager.assign_role_to_user(user, admin_role)

# Asignar un permiso a un rol
{:ok, _} = AuthManager.assign_permission_to_role(admin_role, manage_users)

# Verificar si un usuario tiene un permiso
AuthManager.can?(user, "manage_users")  # true

# Verificar si un usuario tiene un rol
AuthManager.has_role?(user, "administrador")  # true

# Función can_by? flexible
AuthManager.can_by?(user: user, permission: "manage_users")  # true
AuthManager.can_by?(user: user, role: "administrador")  # true
AuthManager.can_by?(role: admin_role, permission: "manage_users")  # true
```

### Autenticación de usuarios

```elixir
alias AuthManager.Accounts.UserService
alias AuthManager.Accounts.Guardian

# Autenticar un usuario
case UserService.authenticate("username", "password") do
  {:ok, user} ->
    # Generar tokens JWT
    access_token = Guardian.create_access_token(user)
    refresh_token = Guardian.create_refresh_token(user)
    # ...
    
  {:error, :invalid_credentials} ->
    # Manejar error de autenticación
    # ...
end

# Verificar un token y obtener el usuario
case Guardian.get_user_from_token(token) do
  {:ok, user} ->
    # Usuario autenticado
    # ...
    
  {:error, _reason} ->
    # Token inválido
    # ...
end

# Refrescar tokens
case Guardian.exchange_refresh_token(refresh_token) do
  {:ok, new_access_token, new_refresh_token} ->
    # ...
    
  {:error, _reason} ->
    # ...
end
```

### Integración con Phoenix

#### Configuración del Router

```elixir
defmodule MyAppWeb.Router do
  use MyAppWeb, :router
  use AuthManager.Phoenix, :router  # Añade macros para autenticación
  
  # Añadir pipeline de autenticación
  auth_pipeline()
  
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    # ...
  end
  
  pipeline :api do
    plug :accepts, ["json"]
  end
  
  pipeline :api_auth do
    plug AuthManager.Accounts.AuthenticationPlug
  end
  
  # Rutas protegidas para la API
  scope "/api", MyAppWeb do
    pipe_through [:api, :api_auth]
    
    resources "/users", UserController
  end
  
  # Añadir rutas de autenticación estándar (opcional)
  # auth_routes()
  
  # Añadir rutas de API de autenticación (opcional)
  # auth_api_routes()
end
```

#### Uso en Controllers

```elixir
defmodule MyAppWeb.UserController do
  use MyAppWeb, :controller
  use AuthManager.Phoenix, :controller  # Añade plugs y helpers para autenticación
  import AuthManager.Core.Middleware
  
  # Verificar autenticación del usuario
  plug :require_authenticated_user when action in [:index, :show, :edit, :update, :delete]
  
  # Verificar un permiso específico
  plug require_permission(permission: "manage_users") when action in [:index, :show, :edit, :update, :delete]
  
  # O usar authorize para verificaciones más complejas
  plug authorize(role: "admin") when action in [:dangerous_action]
  
  def index(conn, _params) do
    users = AuthManager.get_all_users()
    render(conn, "index.html", users: users)
  end
  
  # ...
end
```

### Herencia de roles y permisos

```elixir
# Crear roles con jerarquía
{:ok, editor_role} = AuthManager.create_role(%{
  name: "Editor",
  description: "Puede editar contenido"
})

{:ok, senior_editor_role} = AuthManager.create_role(%{
  name: "Editor Senior",
  description: "Editor con permisos adicionales"
})

# Establecer jerarquía (senior_editor hereda de editor)
{:ok, _} = AuthManager.assign_parent_role(senior_editor_role, editor_role)

# Crear permisos con jerarquía
{:ok, edit_content} = AuthManager.create_permission(%{
  name: "Editar contenido",
  slug: "edit_content"
})

{:ok, publish_content} = AuthManager.create_permission(%{
  name: "Publicar contenido",
  slug: "publish_content"
})

# Asignar permiso al rol padre
{:ok, _} = AuthManager.assign_permission_to_role(editor_role, edit_content)

# Asignar permiso al rol hijo
{:ok, _} = AuthManager.assign_permission_to_role(senior_editor_role, publish_content)

# Un usuario con rol senior_editor tendrá ambos permisos
{:ok, user} = AuthManager.create_user(%{username: "senior_editor", email: "se@example.com", password: "password", first_name: "Senior", last_name: "Editor"})
{:ok, _} = AuthManager.assign_role_to_user(user, senior_editor_role)

# Verificar permisos
AuthManager.can?(user, "edit_content")     # true (heredado del rol editor)
AuthManager.can?(user, "publish_content")  # true (asignado directamente al rol senior_editor)
```

## Herramientas utilitarias

AuthManager incluye varios módulos de herramientas que pueden usarse independientemente:

### StringTools

```elixir
alias AuthManager.Tools.StringTools

StringTools.capitalize_words("hello world")  # "Hello World"
StringTools.to_snake_case("HelloWorld")      # "hello_world"
StringTools.slugify("¡Hola, Mundo!")         # "hola-mundo"
StringTools.to_camel_case("hello_world")     # "helloWorld"
StringTools.to_pascal_case("hello_world")    # "HelloWorld"
StringTools.to_kebab_case("HelloWorld")      # "hello-world"
StringTools.truncate("Hello World", 5)       # "Hello..."
StringTools.to_bytecode("ABC")               # [65, 66, 67]
StringTools.from_bytecode([65, 66, 67])      # "ABC"
StringTools.format_with_pattern("1234567890", "XXX-XXX-XXXX")  # "123-456-7890"
```

### MapTools

```elixir
alias AuthManager.Tools.MapTools

MapTools.keys_to_atoms(%{"name" => "Juan"})       # %{name: "Juan"}
MapTools.keys_to_strings(%{name: "Juan"})         # %{"name" => "Juan"}
MapTools.flatten(%{user: %{name: "Juan"}})        # %{"user.name" => "Juan"}
MapTools.unflatten(%{"user.name" => "Juan"})      # %{"user" => %{"name" => "Juan"}}
MapTools.deep_merge(%{a: 1}, %{b: 2})             # %{a: 1, b: 2}
MapTools.deep_filter(%{a: 1, b: nil}, fn {_,v} -> !is_nil(v) end)  # %{a: 1}
MapTools.deep_map(%{a: 1, b: 2}, fn v -> v * 2 end)  # %{a: 2, b: 4}
MapTools.get_in_path(%{user: %{name: "Juan"}}, "user.name")  # "Juan"
```

### ListTools

```elixir
alias AuthManager.Tools.ListTools

ListTools.flatten([1, [2, 3], [4, [5, 6]]])  # [1, 2, 3, 4, 5, 6]
ListTools.unique([1, 2, 3, 2, 1, 4])         # [1, 2, 3, 4]
ListTools.chunk([1, 2, 3, 4, 5, 6, 7], 3)    # [[1, 2, 3], [4, 5, 6], [7]]
ListTools.intersperse([1, 2, 3], :sep)       # [1, :sep, 2, :sep, 3]
ListTools.compress([1, 1, 2, 3, 3, 3, 4])    # [1, 2, 3, 4]
ListTools.rotate([1, 2, 3, 4, 5], 2)         # [3, 4, 5, 1, 2]
ListTools.sliding_window([1, 2, 3, 4, 5], 3) # [[1, 2, 3], [2, 3, 4], [3, 4, 5]]
ListTools.permutations([1, 2, 3])            # [[1, 2, 3], [1, 3, 2], ...]
ListTools.combinations([1, 2, 3], 2)         # [[1, 2], [1, 3], [2, 3]]
```

### DateTools

```elixir
alias AuthManager.Tools.DateTools

DateTools.age_from_birthdate(~D[1990-05-15])  # Calcula la edad
DateTools.format(~D[2023-05-15], "{D} de {Mfull} de {YYYY}")  # "15 de mayo de 2023"
DateTools.add(~D[2023-05-15], days: 5)        # ~D[2023-05-20]
DateTools.add(~D[2023-05-15], months: 2)      # ~D[2023-07-15]
DateTools.start_of(:month, ~D[2023-05-15])    # ~D[2023-05-01]
DateTools.end_of(:month, ~D[2023-05-15])      # ~D[2023-05-31]
DateTools.between?(~D[2023-05-15], ~D[2023-05-10], ~D[2023-05-20])  # true
DateTools.date_range(~D[2023-05-15], ~D[2023-05-20])  # [~D[2023-05-15], ~D[2023-05-16], ...]
```

### CryptoTools

```elixir
alias AuthManager.Tools.CryptoTools

hash = CryptoTools.hash_password("secretpassword")
CryptoTools.verify_password("secretpassword", hash)  # true

token = CryptoTools.generate_token(16)  # Genera un token aleatorio
CryptoTools.sha256("hello world")       # "b94d27b9934d3e08a52e52d7da7dabfac484efe37a5380ee9088f7ace2efcde9"
CryptoTools.hmac("datos", "secreto")    # Genera un HMAC SHA-256

# Cifrado AES-GCM
key = :crypto.strong_rand_bytes(32)
{ciphertext, iv, tag} = CryptoTools.encrypt("datos secretos", key)
CryptoTools.decrypt(ciphertext, iv, tag, key)  # "datos secretos"

# Más simple con codificación Base64
encrypted = CryptoTools.encrypt_and_encode("datos secretos", key)
CryptoTools.decode_and_decrypt(encrypted, key)  # "datos secretos"
```

## Personalización Avanzada

### Implementar Vistas personalizadas

Puede crear sus propias vistas y controladores que extiendan la funcionalidad básica:

```elixir
defmodule MyAppWeb.AuthView do
  use MyAppWeb, :view
  use AuthManager.Phoenix, :view
  
  # Ahora tienes disponible helpers como logged_in?(conn) y current_user(conn)
  # Puedes añadir funciones personalizadas
  def user_name(user) do
    "#{user.first_name} #{user.last_name}"
  end
end
```

### Extender la API

Puede extender la API creando sus propios módulos que utilicen AuthManager:

```elixir
defmodule MyApp.Auth do
  def create_role_with_permissions(role_attrs, permission_slugs) do
    # Transacción que crea un rol y le asigna permisos
    Ecto.Multi.new()
    |> Ecto.Multi.run(:role, fn _, _ -> 
      AuthManager.create_role(role_attrs)
    end)
    |> Ecto.Multi.run(:permissions, fn _, %{role: role} ->
      results = for slug <- permission_slugs do
        permission = AuthManager.Core.Controller.repo().get_by!(AuthManager.Authorization.Permission, slug: slug)
        AuthManager.assign_permission_to_role(role, permission)
      end
      
      {:ok, results}
    end)
    |> AuthManager.Core.Controller.repo().transaction()
  end
end
```

## Licencia

MIT