defmodule Gitex.Warehouse.PostgresStore do
  @behaviour Gitex.Warehouse.Store

  alias Gitex.Repo
  alias Gitex.Pipeline.Monitor
  import Ecto.Query

  @repository_fields ~w(id name owner language stars forks watchers open_issues created_at updated_at)a

  @impl true
  def write(_table, rows) when rows == [] do
    :ok
  end

  def write(table, row) when is_map(row) do
    write(table, [row])
  end

  def write(table, rows) when is_list(rows) do
    rows = Enum.map(rows, &normalize_row/1)

    case rows do
      [] ->
        :ok

      _ ->
        Repo.insert_all(
          table,
          rows,
          on_conflict: {:replace, @repository_fields},
          conflict_target: [:id]
        )

        Monitor.increment(:loaded, length(rows))
        :ok
    end
  rescue
    exception ->
      Monitor.increment(:failed)
      Monitor.error(:load, exception)

      {:error, exception}
  end

  @impl true
  def read(table, opts \\ []) do
    limit = Keyword.get(opts, :limit, 100)
    query = from t in table, limit: ^limit
    {:ok, Repo.all(query)}
  rescue
    exception ->
      Monitor.increment(:failed)
      Monitor.error(:load, exception)

      {:error, exception}
  end

  @impl true
  def reset(table) do
    query = from t in table
    Repo.delete_all(query)

    :ok
  end

  defp normalize_row(%_{} = row) do
    row
    |> Map.from_struct()
    |> normalize_row_map()
  end

  defp normalize_row(row) when is_map(row) do
    normalize_row_map(row)
  end

  defp normalize_row(row) do
    raise ArgumentError, "unsupported row for warehouse insert: #{inspect(row)}"
  end

  defp normalize_row_map(row) do
    row
    |> Enum.reduce(%{}, fn {key, value}, acc ->
      normalized_key = normalize_key(key)

      if normalized_key do
        Map.put(acc, normalized_key, value)
      else
        acc
      end
    end)
    |> Map.take(@repository_fields)
  end

  defp normalize_key(key) when is_atom(key) do
    if key in @repository_fields, do: key, else: nil
  end

  defp normalize_key(key) when is_binary(key) do
    case key do
      "id" -> :id
      "name" -> :name
      "owner" -> :owner
      "language" -> :language
      "stars" -> :stars
      "forks" -> :forks
      "watchers" -> :watchers
      "open_issues" -> :open_issues
      "created_at" -> :created_at
      "updated_at" -> :updated_at
      _ -> nil
    end
  end

  defp normalize_key(_), do: nil
end
