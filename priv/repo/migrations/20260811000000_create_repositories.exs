defmodule Gitex.Repo.Migrations.CreateRepositories do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:repositories, primary_key: false) do
      add :id, :bigint, primary_key: true
      add :name, :string, null: false
      add :owner, :string, null: false
      add :language, :string
      add :stars, :integer, default: 0, null: false
      add :forks, :integer, default: 0, null: false
      add :watchers, :integer, default: 0, null: false
      add :open_issues, :integer, default: 0, null: false
      add :created_at, :utc_datetime_usec
      add :updated_at, :utc_datetime_usec
    end

    create index(:repositories, [:owner])
    create index(:repositories, [:language])
  end
end
