defmodule AuthManager do
  @moduledoc """
  AuthManager es una librería completa para gestión de usuarios, roles y permisos
  en aplicaciones Phoenix, con soporte para herencia de roles y permisos.

  Proporciona:
  - Gestión de usuarios con datos personales
  - Sistema jerárquico de roles y permisos
  - Verificación y autorización mediante middleware
  - Herramientas utilitarias para varias operaciones comunes
  """

  alias AuthManager.Core.Controller, as: CoreController

  @doc """
  Verifica si un usuario tiene un permiso específico.
  """
  defdelegate can?(user, permission), to: CoreController

  @doc """
  Verifica si un usuario tiene un rol específico.
  """
  defdelegate has_role?(user, role), to: CoreController

  @doc """
  Verifica si un rol incluye un permiso específico.
  """
  defdelegate role_has_permission?(role, permission), to: CoreController

  @doc """
  Función unificada para verificar permisos o roles.
  Ejemplo:
  ```
  AuthManager.can_by?(user: user, permission: "delete_users")
  AuthManager.can_by?(user: user, role: "admin")
  AuthManager.can_by?(role: "editor", permission: "edit_articles")
  ```
  """
  defdelegate can_by?(opts), to: CoreController

  # Funciones para crear usuarios, roles y permisos
  defdelegate create_user(attrs), to: CoreController
  defdelegate create_role(attrs), to: CoreController
  defdelegate create_permission(attrs), to: CoreController

  # Funciones para asignar roles y permisos
  defdelegate assign_role_to_user(user, role), to: CoreController
  defdelegate assign_permission_to_user(user, permission), to: CoreController
  defdelegate assign_permission_to_role(role, permission), to: CoreController
  defdelegate assign_parent_role(role, parent_role), to: CoreController
  defdelegate assign_parent_permission(permission, parent_permission), to: CoreController

  # Funciones para consultas
  defdelegate get_user_permissions(user), to: CoreController
  defdelegate get_user_roles(user), to: CoreController
  defdelegate get_role_permissions(role), to: CoreController
  defdelegate get_all_users(), to: CoreController
  defdelegate get_all_roles(), to: CoreController
  defdelegate get_all_permissions(), to: CoreController
end
