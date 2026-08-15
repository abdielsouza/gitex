defmodule Gitex.Dashboard.Cache do
  @table :gitex_dashboard_cache

  def clear do
    case :ets.whereis(@table) do
      :undefined -> :ok
      _ -> :ets.delete_all_objects(@table)
    end
  end
end
