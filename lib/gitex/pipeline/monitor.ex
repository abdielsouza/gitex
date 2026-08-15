defmodule Gitex.Pipeline.Monitor do
  use GenServer

  @name __MODULE__

  defstruct [
    :started_at,
    :finished_at,
    discovered: 0,
    extracted: 0,
    transformed: 0,
    loaded: 0,
    failed: 0,
    errors: [],
    events: []
  ]

  ## ------- API -------

  def start_link(_) do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: @name)
  end

  def reset do
    GenServer.cast(@name, :reset)
  end

  def increment(metric, amount \\ 1) do
    GenServer.cast(@name, {:increment, metric, amount})
  end

  def error(stage, exception) do
    GenServer.cast(@name, {:error, stage, exception})
  end

  def event(message) do
    GenServer.cast(@name, {:event, message})
  end

  def finish do
    GenServer.cast(@name, :finish)
  end

  def snapshot do
    GenServer.call(@name, :snapshot)
  end

  ## ------- CALLBACKS -------

  @impl true
  def init(_) do
    {:ok, %__MODULE__{started_at: System.monotonic_time(:millisecond)}}
  end

  @impl true
  def handle_cast(:reset, _) do
    {:noreply, %__MODULE__{started_at: System.monotonic_time(:millisecond)}}
  end

  def handle_cast({:increment, metric, amount}, state) do
    state = Map.update!(state, metric, &(&1 + amount))
    broadcast(state)

    {:noreply, state}
  end

  def handle_cast({:event, message}, state) do
    state = %{
      state | events: [
        %{timestamp: DateTime.utc_now(), message: message} | state.events
      ]
    }

    broadcast(state)

    {:noreply, state}
  end

  def handle_cast({:error, stage, exception}, state) do
    state = %{
      state |
      failed: state.failed + 1,
      errors: [
        %{
          stage: stage,
          exception: exception,
          timestamp: DateTime.utc_now()
        } | state.errors
      ]
    }

    broadcast(state)

    {:noreply, state}
  end

  def handle_cast(:finish, state) do
    {:noreply, %{state | finished_at: System.monotonic_time(:millisecond)}}
  end

  @impl true
  def handle_call(:snapshot, _, state) do
    {:reply, enrich(state), state}
  end

  defp enrich(state) do
    now = state.finished_at || System.monotonic_time(:millisecond)
    elapsed = max(now - state.started_at, 1)
    rate = state.loaded / (elapsed / 1000)

    Map.merge(state, %{elapsed_ms: elapsed, repos_per_second: Float.round(rate, 2)})
  end

  defp broadcast(state) do
    Phoenix.PubSub.broadcast(Gitex.PubSub, "pipeline", {:metrics_updated, enrich(state)})
  end
end
