defmodule Gitex.Errors do
  use Agent

  def start_link(_) do
    Agent.start_link(fn -> [] end, name: __MODULE__)
  end

  def add(stage, error) do
    Agent.update(__MODULE__, fn errors ->
      [
        %{
          stage: stage,
          error: inspect(error),
          timestamp: DateTime.utc_now()
        }
        | errors
      ]
    end)
  end

  def all do
    Agent.get(__MODULE__, & &1)
  end
end
