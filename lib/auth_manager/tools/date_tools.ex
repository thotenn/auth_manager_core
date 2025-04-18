defmodule AuthManager.Tools.DateTools do
  @moduledoc """
  Utilidades para manipulación de fechas y tiempos.
  """

  @doc """
  Convierte una fecha a formato ISO 8601.

  ## Ejemplos

      iex> DateTools.to_iso8601(~D[2023-05-15])
      "2023-05-15"

      iex> DateTools.to_iso8601(~N[2023-05-15 10:30:45])
      "2023-05-15T10:30:45"
  """
  def to_iso8601(%Date{} = date) do
    Date.to_iso8601(date)
  end

  def to_iso8601(%NaiveDateTime{} = naive) do
    NaiveDateTime.to_iso8601(naive)
  end

  def to_iso8601(%DateTime{} = datetime) do
    DateTime.to_iso8601(datetime)
  end

  @doc """
  Convierte una fecha a una cadena formateada.

  ## Ejemplos

      iex> DateTools.format(~D[2023-05-15], "{YYYY}-{0M}-{0D}")
      "2023-05-15"

      iex> DateTools.format(~D[2023-05-15], "{D} de {Mfull} de {YYYY}")
      "15 de mayo de 2023"
  """
  def format(%Date{} = date, format) do
    Calendar.strftime(date, format)
  end

  def format(%NaiveDateTime{} = naive, format) do
    Calendar.strftime(naive, format)
  end

  def format(%DateTime{} = datetime, format) do
    Calendar.strftime(datetime, format)
  end

  @doc """
  Calcula la diferencia en días entre dos fechas.

  ## Ejemplos

      iex> DateTools.days_between(~D[2023-05-15], ~D[2023-05-20])
      5
  """
  def days_between(%Date{} = date1, %Date{} = date2) do
    Date.diff(date2, date1)
  end

  @doc """
  Calcula la edad en años a partir de una fecha de nacimiento.

  ## Ejemplos

      iex> DateTools.age_from_birthdate(~D[1990-05-15])
      # Retorna la edad actual, basada en la fecha actual
  """
  def age_from_birthdate(%Date{} = birthdate) do
    today = Date.utc_today()

    years = today.year - birthdate.year

    # Ajustar si aún no ha pasado el cumpleaños este año
    if {today.month, today.day} < {birthdate.month, birthdate.day} do
      years - 1
    else
      years
    end
  end

  @doc """
  Añade un número específico de días, meses o años a una fecha.

  ## Ejemplos

      iex> DateTools.add(~D[2023-05-15], days: 5)
      ~D[2023-05-20]

      iex> DateTools.add(~D[2023-05-15], months: 2)
      ~D[2023-07-15]

      iex> DateTools.add(~D[2023-05-15], years: 1)
      ~D[2024-05-15]
  """
  def add(%Date{} = date, opts) do
    days = Keyword.get(opts, :days, 0)
    months = Keyword.get(opts, :months, 0)
    years = Keyword.get(opts, :years, 0)

    date
    |> Date.add(days)
    |> add_months(months)
    |> add_years(years)
  end

  defp add_months(date, 0), do: date
  defp add_months(date, months) do
    %{year: year, month: month} = date

    total_months = month + months
    new_month = rem(total_months - 1, 12) + 1
    years_to_add = div(total_months - 1, 12)

    %{date | year: year + years_to_add, month: new_month}
    |> ensure_valid_date()
  end

  defp add_years(date, 0), do: date
  defp add_years(date, years) do
    %{date | year: date.year + years}
    |> ensure_valid_date()
  end

  defp ensure_valid_date(%{year: _year, month: _month, day: day} = date) do
    days_in_month = Date.days_in_month(%{date | day: 1})

    if day > days_in_month do
      %{date | day: days_in_month}
    else
      date
    end
  end

  @doc """
  Devuelve el inicio del período (día, semana, mes, trimestre, año) para una fecha dada.

  ## Ejemplos

      iex> DateTools.start_of(:month, ~D[2023-05-15])
      ~D[2023-05-01]

      iex> DateTools.start_of(:year, ~D[2023-05-15])
      ~D[2023-01-01]
  """
  def start_of(:day, %Date{} = date), do: date

  def start_of(:week, %Date{} = date) do
    # Considerando que la semana comienza el lunes (1) y termina el domingo (7)
    days_from_week_start = Date.day_of_week(date) - 1
    Date.add(date, -days_from_week_start)
  end

  def start_of(:month, %Date{} = date) do
    %{year: date.year, month: date.month, day: 1}
    |> Date.from_erl!()
  end

  def start_of(:quarter, %Date{} = date) do
    quarter_month = (div(date.month - 1, 3) * 3) + 1

    %{year: date.year, month: quarter_month, day: 1}
    |> Date.from_erl!()
  end

  def start_of(:year, %Date{} = date) do
    %{year: date.year, month: 1, day: 1}
    |> Date.from_erl!()
  end

  @doc """
  Devuelve el fin del período (día, semana, mes, trimestre, año) para una fecha dada.

  ## Ejemplos

      iex> DateTools.end_of(:month, ~D[2023-05-15])
      ~D[2023-05-31]

      iex> DateTools.end_of(:year, ~D[2023-05-15])
      ~D[2023-12-31]
  """
  def end_of(:day, %Date{} = date), do: date

  def end_of(:week, %Date{} = date) do
    # Considerando que la semana comienza el lunes (1) y termina el domingo (7)
    days_to_week_end = 7 - Date.day_of_week(date)
    Date.add(date, days_to_week_end)
  end

  def end_of(:month, %Date{} = date) do
    days_in_month = Date.days_in_month(date)

    %{year: date.year, month: date.month, day: days_in_month}
    |> Date.from_erl!()
  end

  def end_of(:quarter, %Date{} = date) do
    quarter_last_month = (div(date.month - 1, 3) * 3) + 3

    end_date = %{year: date.year, month: quarter_last_month, day: 1}
               |> Date.from_erl!()

    days_in_month = Date.days_in_month(end_date)

    %{end_date | day: days_in_month}
  end

  def end_of(:year, %Date{} = date) do
    %{year: date.year, month: 12, day: 31}
    |> Date.from_erl!()
  end

  @doc """
  Determina si una fecha está entre dos fechas.

  ## Ejemplos

      iex> DateTools.between?(~D[2023-05-15], ~D[2023-05-10], ~D[2023-05-20])
      true
  """
  def between?(%Date{} = date, %Date{} = from, %Date{} = to) do
    Date.compare(date, from) != :lt and Date.compare(date, to) != :gt
  end

  @doc """
  Obtiene una lista de fechas en un rango.

  ## Ejemplos

      iex> DateTools.date_range(~D[2023-05-15], ~D[2023-05-20])
      [~D[2023-05-15], ~D[2023-05-16], ~D[2023-05-17], ~D[2023-05-18], ~D[2023-05-19], ~D[2023-05-20]]
  """
  def date_range(%Date{} = from, %Date{} = to) do
    if Date.compare(from, to) == :gt do
      []
    else
      days = Date.diff(to, from)

      for i <- 0..days do
        Date.add(from, i)
      end
    end
  end
end
