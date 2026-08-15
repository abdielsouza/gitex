defmodule Gitex.Pipeline.Item do
  @enforce_keys [:type, :name]

  defstruct [:type, :name]
end
