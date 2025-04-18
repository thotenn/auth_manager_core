defmodule AuthManager.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Inicia el repositorio de la aplicación huésped si está configurado
      maybe_repo_child_spec()
    ] |> Enum.filter(&(&1 != nil))

    opts = [strategy: :one_for_one, name: AuthManager.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp maybe_repo_child_spec do
    case Application.get_env(:auth_manager, :repo) do
      nil -> nil
      repo -> repo
    end
  end
end
