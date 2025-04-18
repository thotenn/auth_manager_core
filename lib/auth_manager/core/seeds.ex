defmodule AuthManager.Core.Seeds do
  @moduledoc """
  Funciones para sembrar la base de datos con datos iniciales.
  """
  alias AuthManager.Core.Controller

  @doc """
  Crea los roles y permisos básicos del sistema.

  Roles:
  - admin: Administrador del sistema con todos los permisos
  - manager: Gerente con permisos de gestión
  - user: Usuario básico

  Permisos (por categoría):
  - users: Gestión de usuarios
  - roles: Gestión de roles
  - permissions: Gestión de permisos
  - system: Configuración del sistema
  """
  def create_basic_seeds do
    # Crear roles básicos
    {:ok, admin_role} = Controller.create_role(%{
      name: "Administrador",
      slug: "admin",
      description: "Administrador del sistema con acceso completo"
    })

    {:ok, manager_role} = Controller.create_role(%{
      name: "Gerente",
      slug: "manager",
      description: "Gerente con permisos de gestión"
    })

    {:ok, user_role} = Controller.create_role(%{
      name: "Usuario",
      slug: "user",
      description: "Usuario básico del sistema"
    })

    # Establecer jerarquía de roles
    Controller.assign_parent_role(manager_role, user_role)
    Controller.assign_parent_role(admin_role, manager_role)

    # Crear permisos por categoría
    # Permisos de Usuarios
    {:ok, users_view} = Controller.create_permission(%{
      name: "Ver usuarios",
      slug: "users:view",
      description: "Permite ver la lista de usuarios"
    })

    {:ok, users_create} = Controller.create_permission(%{
      name: "Crear usuarios",
      slug: "users:create",
      description: "Permite crear nuevos usuarios"
    })

    {:ok, users_edit} = Controller.create_permission(%{
      name: "Editar usuarios",
      slug: "users:edit",
      description: "Permite editar usuarios existentes"
    })

    {:ok, users_delete} = Controller.create_permission(%{
      name: "Eliminar usuarios",
      slug: "users:delete",
      description: "Permite eliminar usuarios"
    })

    # Permisos de Roles
    {:ok, roles_view} = Controller.create_permission(%{
      name: "Ver roles",
      slug: "roles:view",
      description: "Permite ver la lista de roles"
    })

    {:ok, roles_create} = Controller.create_permission(%{
      name: "Crear roles",
      slug: "roles:create",
      description: "Permite crear nuevos roles"
    })

    {:ok, roles_edit} = Controller.create_permission(%{
      name: "Editar roles",
      slug: "roles:edit",
      description: "Permite editar roles existentes"
    })

    {:ok, roles_delete} = Controller.create_permission(%{
      name: "Eliminar roles",
      slug: "roles:delete",
      description: "Permite eliminar roles"
    })

    # Permisos de Permisos
    {:ok, permissions_view} = Controller.create_permission(%{
      name: "Ver permisos",
      slug: "permissions:view",
      description: "Permite ver la lista de permisos"
    })

    {:ok, permissions_create} = Controller.create_permission(%{
      name: "Crear permisos",
      slug: "permissions:create",
      description: "Permite crear nuevos permisos"
    })

    {:ok, permissions_edit} = Controller.create_permission(%{
      name: "Editar permisos",
      slug: "permissions:edit",
      description: "Permite editar permisos existentes"
    })

    {:ok, permissions_delete} = Controller.create_permission(%{
      name: "Eliminar permisos",
      slug: "permissions:delete",
      description: "Permite eliminar permisos"
    })

    # Permisos de sistema
    {:ok, system_settings} = Controller.create_permission(%{
      name: "Configuraciones del sistema",
      slug: "system:settings",
      description: "Permite modificar las configuraciones del sistema"
    })

    {:ok, system_logs} = Controller.create_permission(%{
      name: "Ver logs del sistema",
      slug: "system:logs",
      description: "Permite ver los logs del sistema"
    })

    # Asignar permisos a roles

    # Usuario puede ver usuarios y roles
    Controller.assign_permission_to_role(user_role, users_view)
    Controller.assign_permission_to_role(user_role, roles_view)

    # Gerente puede gestionar usuarios y ver permisos
    Controller.assign_permission_to_role(manager_role, users_create)
    Controller.assign_permission_to_role(manager_role, users_edit)
    Controller.assign_permission_to_role(manager_role, permissions_view)
    Controller.assign_permission_to_role(manager_role, roles_edit)

    # Administrador tiene todos los permisos restantes
    Controller.assign_permission_to_role(admin_role, users_delete)
    Controller.assign_permission_to_role(admin_role, roles_create)
    Controller.assign_permission_to_role(admin_role, roles_delete)
    Controller.assign_permission_to_role(admin_role, permissions_create)
    Controller.assign_permission_to_role(admin_role, permissions_edit)
    Controller.assign_permission_to_role(admin_role, permissions_delete)
    Controller.assign_permission_to_role(admin_role, system_settings)
    Controller.assign_permission_to_role(admin_role, system_logs)

    # Crear usuario administrador por defecto
    {:ok, admin_user} = Controller.create_user(%{
      first_name: "Admin",
      last_name: "System",
      username: "admin",
      email: "admin@system.com",
      password: "Admin123!",
      is_active: true
    })

    # Asignar rol de administrador
    Controller.assign_role_to_user(admin_user, admin_role)

    %{
      roles: %{
        admin: admin_role,
        manager: manager_role,
        user: user_role
      },
      permissions: %{
        users_view: users_view,
        users_create: users_create,
        users_edit: users_edit,
        users_delete: users_delete,
        roles_view: roles_view,
        roles_create: roles_create,
        roles_edit: roles_edit,
        roles_delete: roles_delete,
        permissions_view: permissions_view,
        permissions_create: permissions_create,
        permissions_edit: permissions_edit,
        permissions_delete: permissions_delete,
        system_settings: system_settings,
        system_logs: system_logs
      },
      users: %{
        admin: admin_user
      }
    }
  end

  @doc """
  Comprueba si las semillas ya han sido creadas,
  para evitar crear duplicados.
  """
  def seeds_exist? do
    admin_role = Controller.repo().get_by(AuthManager.Authorization.Role, slug: "admin")
    admin_user = Controller.repo().get_by(AuthManager.Accounts.User, username: "admin")

    not is_nil(admin_role) and not is_nil(admin_user)
  end

  @doc """
  Crea las semillas solo si no existen ya.
  Devuelve :ok si las semillas ya existían o fueron creadas con éxito.
  """
  def ensure_seeds_exist do
    if seeds_exist?() do
      :ok
    else
      create_basic_seeds()
      :ok
    end
  end
end
