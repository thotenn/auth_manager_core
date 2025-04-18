defmodule AuthManager.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/thotenn/auth_manager_core"

  def project do
    [
      app: :auth_manager,
      version: @version,
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: description(),
      package: package(),
      aliases: aliases(),
      elixirc_paths: elixirc_paths(Mix.env()),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {AuthManager.Application, []}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Phoenix Framework (última versión)
      {:phoenix, "~> 1.7.10"},
      {:phoenix_ecto, "~> 4.4"},

      # Base de datos
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0", optional: true},

      # Autenticación
      {:bcrypt_elixir, "~> 3.0"},
      {:guardian, "~> 2.3"},

      # Herramientas de desarrollo
      {:ex_doc, "~> 0.30", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},

      # Validación
      {:ecto_enum, "~> 1.4"}
    ]
  end

  defp description do
    """
    Una librería completa para gestión de usuarios, roles y permisos
    en aplicaciones Phoenix, con soporte para herencia de roles y permisos.
    """
  end

  defp package do
    [
      maintainers: ["thotenn"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(lib LICENSE mix.exs README.md)
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing"],
      "assets.build": ["tailwind default"],
      "assets.deploy": ["tailwind default --minify"]
    ]
  end
end
