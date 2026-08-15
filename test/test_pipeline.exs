defmodule Gitex.PipelineTest do
  use ExUnit.Case, async: true

  alias Gitex.Models.Repository
  alias Gitex.Pipeline.Extractor
  alias Gitex.Pipeline.Monitor
  alias Gitex.Pipeline.Transformer

  setup do
    start_supervised!({Phoenix.PubSub, name: Gitex.PubSub})
    start_supervised!(Monitor)
    :ok
  end

  test "normalize_response wraps a single repository payload into a list" do
    repo = %{"id" => 42, "name" => "gitex"}

    assert Extractor.normalize_response(repo, false) == [repo]
    assert Extractor.normalize_response([repo], true) == [repo]
  end

  test "transform/1 parses ISO-8601 timestamps into DateTime structs" do
    data = %{
      "id" => 42,
      "name" => "gitex",
      "owner" => %{"login" => "abdielsouza"},
      "language" => nil,
      "stargazers_count" => 12,
      "forks_count" => 3,
      "watchers_count" => 5,
      "open_issues" => 1,
      "created_at" => "2024-01-01T00:00:00Z",
      "updated_at" => "2024-01-02T00:00:00Z"
    }

    assert %Repository{
             created_at: %DateTime{},
             updated_at: %DateTime{}
           } = Transformer.process(data)
  end

  test "transform/1 accepts repositories with nil language values" do
    data = %{
      "id" => 42,
      "name" => "gitex",
      "owner" => %{"login" => "abdielsouza"},
      "language" => nil,
      "stargazers_count" => 12,
      "forks_count" => 3,
      "watchers_count" => 5,
      "open_issues" => 1,
      "created_at" => "2024-01-01T00:00:00Z",
      "updated_at" => "2024-01-02T00:00:00Z"
    }

    assert %Repository{
             id: 42,
             name: "gitex",
             owner: "abdielsouza",
             language: nil,
             stars: 12
           } = Transformer.process(data)
  end
end
