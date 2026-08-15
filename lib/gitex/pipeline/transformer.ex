defmodule Gitex.Pipeline.Transformer do
  alias Gitex.Models.Repository
  alias Gitex.Pipeline.Monitor

  def process(data) when is_map(data) do
    repository = %Repository{
      id: extract(data, ["id", :id]),
      name: extract(data, ["name", :name]),
      owner: extract_owner(data),
      language: extract(data, ["language", :language]),
      stars: extract(data, ["stargazers_count", :stargazers_count]),
      forks: extract(data, ["forks_count", :forks_count]),
      watchers: extract(data, ["watchers_count", :watchers_count]),
      open_issues: extract(data, ["open_issues", :open_issues]),
      created_at: normalize_datetime(extract(data, ["created_at", :created_at])),
      updated_at: normalize_datetime(extract(data, ["updated_at", :updated_at]))
    }

    if is_nil(repository.id) or is_nil(repository.name) or is_nil(repository.owner) do
      Monitor.increment(:failed)
      Monitor.error(:transform, "missing required repository fields")
      nil
    else
      Monitor.increment(:transformed)
      repository
    end
  rescue
    exception ->
      Monitor.increment(:failed)
      Monitor.error(:transform, exception)
      nil
  end

  def process(_), do: nil

  defp extract(data, keys) do
    Enum.find_value(keys, fn key ->
      case data do
        %{^key => value} -> value
        %{} -> Map.get(data, key)
        _ -> nil
      end
    end)
  end

  defp extract_owner(data) do
    extract(data, ["owner", :owner])
    |> case do
      %{"login" => login} -> login
      %{login: login} -> login
      login when is_binary(login) -> login
      _ -> nil
    end
  end

  defp normalize_datetime(value) when is_binary(value) do
    case DateTime.from_iso8601(value) do
      {:ok, datetime, _offset} -> datetime
      {:error, _} ->
        case NaiveDateTime.from_iso8601(value) do
          {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
          {:error, _} -> nil
        end
    end
  end

  defp normalize_datetime(%DateTime{} = value), do: value
  defp normalize_datetime(%NaiveDateTime{} = value), do: DateTime.from_naive!(value, "Etc/UTC")
  defp normalize_datetime(_), do: nil
end
