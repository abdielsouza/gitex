defmodule Gitex.Pipeline.Discovery do
  alias Gitex.Pipeline.Item

  def repositories(repos) do
    repos |> Stream.map(fn repo ->
      %Item{type: :repository, name: repo}
    end)
  end

  def users(users) do
    users |> Stream.map(fn user ->
      %Item{type: :user, name: user}
    end)
  end

  def organizations(orgs) do
    orgs |> Stream.map(fn org ->
      %Item{type: :organization, name: org}
    end)
  end

  def discover(opts) do
    Stream.concat([
      repositories(opts.repositories),
      users(opts.users),
      organizations(opts.organizations)
    ])
  end
end
