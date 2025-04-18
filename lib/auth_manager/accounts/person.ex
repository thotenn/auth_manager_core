defmodule AuthManager.Accounts.Person do
  @moduledoc """
  Esquema abstracto que define los campos comunes para datos personales.
  Este esquema será utilizado como un comportamiento que será implementado por User.
  """

  defmacro __using__(_) do
    quote do
      import AuthManager.Accounts.Person, only: [person_fields: 0, person_validations: 0]

      # Callbacks
      def person_changeset(person, attrs) do
        person
        |> Ecto.Changeset.cast(attrs, [
          :first_name, :last_name, :birth_date, :gender,
          :identity_document, :phone, :address, :city,
          :state, :country, :postal_code
        ])
        |> Ecto.Changeset.validate_required([:first_name, :last_name])
        |> validate_person_fields()
      end

      # Validaciones específicas para campos personales
      defp validate_person_fields(changeset) do
        changeset
        |> validate_format_if_present(:phone, ~r/^\+?[0-9]{7,15}$/,
           message: "debe ser un número de teléfono válido")
        |> validate_format_if_present(:postal_code, ~r/^[0-9a-zA-Z\s\-]{3,10}$/,
           message: "debe ser un código postal válido")
      end

      # Función auxiliar para validar el formato sólo si el campo está presente
      defp validate_format_if_present(changeset, field, format, opts \\ []) do
        if value = Ecto.Changeset.get_change(changeset, field) do
          Ecto.Changeset.validate_format(changeset, field, format, opts)
        else
          changeset
        end
      end

      # Getter para el nombre completo
      def full_name(%{first_name: first_name, last_name: last_name}) do
        "#{first_name} #{last_name}"
      end
      def full_name(_), do: nil
    end
  end

  # Define a macro that we can use in schemas
  defmacro person_fields do
    quote do
      field :first_name, :string
      field :last_name, :string
      field :full_name, :string, virtual: true
      field :birth_date, :date
      field :gender, :string
      field :identity_document, :string
      field :phone, :string
      field :address, :string
      field :city, :string
      field :state, :string
      field :country, :string
      field :postal_code, :string
    end
  end

  # Define any validations as needed
  defmacro person_validations do
    quote do
      # Add any common validation functions here
    end
  end
end
