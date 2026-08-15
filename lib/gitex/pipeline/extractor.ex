defmodule Gitex.Pipeline.Extractor do
  alias Gitex.Utils.GithubClient
  alias Gitex.Pipeline.Monitor
  alias Gitex.Pipeline.Item

  def process(%Item{type: :repository, name: name}) do
    fetch("/repos/#{name}")
  end

  def process(%Item{type: :user, name: name}) do
    fetch("/users/#{name}/repos", single: true)
  end

  def process(%Item{type: :organization, name: name}) do
    fetch("/orgs/#{name}/repos", single: true)
  end

  def process(_) do
    {:error, :invalid_url}
  end

  def normalize_response(response, single \\ false) do
    cond do
      is_list(response) -> response
      single -> List.wrap(response)
      true -> [response]
    end
  end

  defp fetch(url, single \\ false) do
    try do
      repos = GithubClient.get(url) |> normalize_response(single)
      count = length(repos)

      Monitor.increment(:discovered, count)
      Monitor.increment(:extracted, count)

      repos
    rescue
      exception ->
        Monitor.increment(:failed)
        Monitor.error(:extract, exception)
        []
    end
  end
end
