defmodule Gitex.Warehouse.Store do
  @callback write(atom(), list(map())) :: :ok | {:error, term()}
  @callback read(atom(), keyword()) :: {:ok, list(map())} | {:error, term()}
  @callback reset(atom()) :: :ok
end
