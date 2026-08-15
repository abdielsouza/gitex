defmodule GitexWeb.DashboardLive do
  use GitexWeb, :live_view

  alias Gitex.Dashboard.Cache
  alias Gitex.Pipeline
  alias Gitex.Pipeline.Monitor
  alias Gitex.Repo
  import Ecto.Query

  @default_filters %{language: "", owner: "", limit: "5"}

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Gitex.PubSub, "pipeline")
    end

    filters = @default_filters

    {:ok,
     socket
     |> assign(:pipeline_snapshot, Monitor.snapshot())
     |> assign(:pipeline_form, default_form())
     |> assign(:filter_form, filter_form(filters))
     |> assign(:filters, filters)
     |> assign(:dashboard, build_dashboard_data(filters))
     |> assign(:pipeline_running, false)}
  end

  @impl true
  @spec handle_event(<<_::64, _::_*8>>, any(), map()) :: {:noreply, map()}
  def handle_event("run_pipeline", %{"pipeline" => params}, socket) do
    Task.start(fn ->
      Pipeline.run(parse_targets(params))
    end)

    Cache.clear()

    {:noreply,
     socket
     |> assign(:pipeline_running, true)
     |> put_flash(:info, "Pipeline iniciada com os valores informados.")
     |> assign(:pipeline_form, default_form(params))}
  end

  @impl true
  def handle_event("apply_filters", %{"filters" => params}, socket) do
    filters = normalize_filters(params)

    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:filter_form, filter_form(filters))
     |> assign(:dashboard, build_dashboard_data(filters))}
  end

  @impl true
  def handle_event("clear_cache", _params, socket) do
    Cache.clear()

    {:noreply,
     socket
     |> put_flash(:info, "Cache do dashboard limpado com sucesso.")
     |> assign(:dashboard, build_dashboard_data(socket.assigns.filters))}
  end

  @impl true
  def handle_info({:metrics_updated, snapshot}, socket) do
    was_running = socket.assigns.pipeline_running
    finished? = not is_nil(snapshot.finished_at)

    socket =
      socket
      |> assign(:pipeline_snapshot, snapshot)
      |> assign(:dashboard, build_dashboard_data(socket.assigns.filters))

    socket =
      if was_running and finished? do
        socket
        |> assign(:pipeline_running, false)
        |> put_flash(:info, "Pipeline finalizada com sucesso!")
      else
        if finished?, do: assign(socket, :pipeline_running, false), else: socket
      end

    {:noreply, socket}
  end

  defp build_dashboard_data(filters) do
    language_filter = normalize_filter(filters[:language] || filters["language"])
    owner_filter = normalize_filter(filters[:owner] || filters["owner"])
    limit = parse_limit(filters[:limit] || filters["limit"])

    %{
      total_repositories: total_repositories(language_filter, owner_filter),
      total_stars: total_stars(language_filter, owner_filter),
      total_forks: total_forks(language_filter, owner_filter),
      total_watchers: total_watchers(language_filter, owner_filter),
      total_issues: total_issues(language_filter, owner_filter),
      unique_languages: unique_languages(language_filter, owner_filter),
      unique_owners: unique_owners(language_filter, owner_filter),
      latest_updated: latest_updated(language_filter, owner_filter),
      top_languages: top_languages(language_filter, owner_filter, limit),
      top_owners: top_owners(language_filter, owner_filter, limit),
      last_events: last_events(),
      language_filter: language_filter,
      owner_filter: owner_filter,
      limit: limit
    }
  end

  defp base_repository_query(language, owner) do
    query = from(r in "repositories")

    query = filter_language(query, language)
    filter_owner(query, owner)
  end

  defp filter_language(query, language) do
    if language == "" do
      query
    else
      from(r in query, where: r.language == ^language)
    end
  end

  defp filter_owner(query, owner) do
    if owner == "" do
      query
    else
      from(r in query, where: r.owner == ^owner)
    end
  end

  defp total_repositories(language, owner) do
    base_repository_query(language, owner)
    |> Repo.aggregate(:count, :id)
  end

  defp total_stars(language, owner) do
    base_repository_query(language, owner)
    |> Repo.aggregate(:sum, :stars)
    |> case do
      nil -> 0
      value -> value
    end
  end

  defp total_forks(language, owner) do
    base_repository_query(language, owner)
    |> Repo.aggregate(:sum, :forks)
    |> case do
      nil -> 0
      value -> value
    end
  end

  defp total_watchers(language, owner) do
    base_repository_query(language, owner)
    |> Repo.aggregate(:sum, :watchers)
    |> case do
      nil -> 0
      value -> value
    end
  end

  defp total_issues(language, owner) do
    base_repository_query(language, owner)
    |> Repo.aggregate(:sum, :open_issues)
    |> case do
      nil -> 0
      value -> value
    end
  end

  defp unique_languages(language, owner) do
    base_repository_query(language, owner)
    |> where([r], not is_nil(r.language))
    |> distinct(true)
    |> select([r], r.language)
    |> Repo.all()
    |> length()
  end

  defp unique_owners(language, owner) do
    base_repository_query(language, owner)
    |> distinct(true)
    |> select([r], r.owner)
    |> Repo.all()
    |> length()
  end

  defp latest_updated(language, owner) do
    base_repository_query(language, owner)
    |> order_by([r], desc: r.updated_at)
    |> limit(1)
    |> select([r], r.updated_at)
    |> Repo.one()
  end

  defp top_languages(language, owner, limit) do
    base_repository_query(language, owner)
    |> where([r], not is_nil(r.language))
    |> group_by([r], r.language)
    |> order_by([r], desc: count(r.id))
    |> limit(^limit)
    |> select([r], %{name: r.language, count: count(r.id)})
    |> Repo.all()
  end

  defp top_owners(language, owner, limit) do
    base_repository_query(language, owner)
    |> group_by([r], r.owner)
    |> order_by([r], desc: count(r.id))
    |> limit(^limit)
    |> select([r], %{name: r.owner, count: count(r.id)})
    |> Repo.all()
  end

  defp last_events do
    Monitor.snapshot().events
    |> Enum.take(6)
  end

  defp default_form(params \\ %{}) do
    to_form(%{
      repositories: Map.get(params, "repositories", ""),
      users: Map.get(params, "users", ""),
      organizations: Map.get(params, "organizations", "")
    }, as: :pipeline)
  end

  defp filter_form(params) do
    to_form(%{
      language: Map.get(params, :language, "") || Map.get(params, "language", ""),
      owner: Map.get(params, :owner, "") || Map.get(params, "owner", ""),
      limit: Map.get(params, :limit, "5") || Map.get(params, "limit", "5")
    }, as: :filters)
  end

  defp normalize_filters(params) do
    %{
      language: normalize_filter(Map.get(params, "language") || Map.get(params, :language)),
      owner: normalize_filter(Map.get(params, "owner") || Map.get(params, :owner)),
      limit: parse_limit(Map.get(params, "limit") || Map.get(params, :limit)) |> Integer.to_string()
    }
  end

  defp normalize_filter(value) when is_binary(value), do: String.trim(value)
  defp normalize_filter(nil), do: ""
  defp normalize_filter(value), do: to_string(value)

  defp parse_limit(value) when is_integer(value), do: value
  defp parse_limit(value) when is_binary(value) do
    case Integer.parse(value) do
      {parsed, _} -> max(parsed, 1)
      :error -> 5
    end
  end
  defp parse_limit(_), do: 5

  defp parse_targets(params) do
    %{
      repositories: parse_input(Map.get(params, "repositories", "")),
      users: parse_input(Map.get(params, "users", "")),
      organizations: parse_input(Map.get(params, "organizations", ""))
    }
  end

  defp parse_input(value) when is_binary(value) do
    value
    |> String.split(["\n", ","])
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp parse_input(value) when is_list(value), do: value
  defp parse_input(_), do: []

  defp bar_chart(assigns) do
    max_value =
      assigns.items
      |> Enum.map(& &1.count)
      |> Enum.max(fn -> 1 end)

    assigns = assign(assigns, :max_value, max_value)

    ~H"""
    <div class="space-y-3">
      <%= for item <- @items do %>
        <% width = if @max_value > 0, do: max(8, (item.count / @max_value) * 100), else: 0 %>
        <div class="min-w-0 space-y-1">
          <div class="flex items-center justify-between gap-2">
            <span class="truncate text-sm font-medium text-base-content/90">{item.name}</span>
            <span class={@badge_class}>{format_number(item.count)}</span>
          </div>
          <div class="h-2.5 w-full overflow-hidden rounded-full bg-base-300">
            <div class={["h-full rounded-full", @bar_class]} style={"width: #{width}%"} />
          </div>
        </div>
      <% end %>
    </div>
    """
  end

  def format_number(value) when is_integer(value) do
    value
    |> Integer.to_string()
    |> String.reverse()
    |> String.graphemes()
    |> Enum.chunk_every(3)
    |> Enum.join(".")
    |> String.reverse()
  end

  def format_number(value) when is_float(value) do
    :erlang.float_to_binary(value, decimals: 2)
  end

  def format_number(value), do: to_string(value)

  def format_datetime(nil), do: "—"

  def format_datetime(value) when is_struct(value, DateTime) do
    Calendar.strftime(value, "%y-%m-%d %I:%M:%S %p")
  end

  def format_datetime(value), do: to_string(value)

  def metric_card(assigns) do
    ~H"""
    <div class="card min-w-0 border border-base-300 bg-base-100 shadow-sm">
      <div class="card-body p-4 sm:p-5">
        <p class="text-[10px] font-medium uppercase tracking-[0.2em] text-base-content/60 sm:text-xs">{@title}</p>
        <div class="mt-4 flex items-end justify-between gap-3">
          <span class="break-words text-2xl font-bold text-base-content sm:text-3xl">{@value}</span>
          <span class="badge badge-soft badge-primary">{@subtitle}</span>
        </div>
      </div>
    </div>
    """
  end
end
