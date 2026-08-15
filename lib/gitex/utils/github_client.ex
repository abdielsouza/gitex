defmodule Gitex.Utils.GithubClient do
  @base_url "https://api.github.com"

  def get(path) do
    Req.get!("#{@base_url}#{path}", headers: github_headers())
    |> Map.fetch!(:body)
  end

  defp github_headers do
    [
      {"Accept", "application/vnd.github+json"},
      {"User-Agent", "gitex-etl"}
    ]
  end
end
