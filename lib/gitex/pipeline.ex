defmodule Gitex.Pipeline do
  alias Gitex.Pipeline.Discovery
  alias Gitex.Pipeline.Extractor
  alias Gitex.Pipeline.Monitor
  alias Gitex.Pipeline.Transformer
  alias Gitex.Warehouse.PostgresStore

  def run(opts \\ %{}) do
    opts = normalize_opts(opts)

    Monitor.reset()
    Monitor.event("reset_database")
    PostgresStore.reset("repositories")
    Monitor.event("pipeline_started")

    result =
      opts
      |> Discovery.discover()
      |> Task.async_stream(
        &Extractor.process/1,
        max_concurrency: System.schedulers_online() * 4,
        ordered: false,
        timeout: :infinity
      )
      |> Stream.flat_map(fn
        {:ok, repos} -> repos
        _ -> []
      end)
      |> Stream.map(&Transformer.process/1)
      |> Stream.filter(& &1)
      |> Enum.each(&PostgresStore.write("repositories", &1))

    Monitor.finish()
    Monitor.event("pipeline_finished")
    result
  end

  defp normalize_opts(opts) when is_map(opts) do
    %{
      repositories: normalize_list(Map.get(opts, :repositories, []) ++ Map.get(opts, "repositories", [])),
      users: normalize_list(Map.get(opts, :users, []) ++ Map.get(opts, "users", [])),
      organizations: normalize_list(Map.get(opts, :organizations, []) ++ Map.get(opts, "organizations", []))
    }
  end

  defp normalize_opts(opts) when is_list(opts) do
    %{
      repositories: normalize_list(Keyword.get(opts, :repositories, []) ++ Keyword.get(opts, "repositories", [])),
      users: normalize_list(Keyword.get(opts, :users, []) ++ Keyword.get(opts, "users", [])),
      organizations: normalize_list(Keyword.get(opts, :organizations, []) ++ Keyword.get(opts, "organizations", []))
    }
  end

  defp normalize_opts(_), do: %{repositories: [], users: [], organizations: []}

  defp normalize_list(value) when is_list(value), do: value
  defp normalize_list(value) when is_nil(value), do: []
  defp normalize_list(value), do: List.wrap(value)
end
