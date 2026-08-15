defmodule Gitex.Models.Repository do
    @enforce_keys [:id, :name, :owner]

    @derive Jason.Encoder

    defstruct [
        :id,
        :name,
        :owner,
        :language,
        :stars,
        :forks,
        :watchers,
        :open_issues,
        :created_at,
        :updated_at,
    ]
end
