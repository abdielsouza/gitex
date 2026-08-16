import Config

# Load environment variables from a local .env in dev/test when Dotenvy
# is available. This keeps secrets out of source control while allowing
# local development using a .env file.
if config_env() in [:dev, :test] do
  if Code.ensure_loaded?(Dotenvy) and File.exists?(".env") do
    Dotenvy.source!([".env"])
  end

  # Prefer a full DB URL, but fall back to composing one from parts.
  db_url = Dotenvy.env!("DATABASE_URL")

  config :gitex, Gitex.Repo,
    url: db_url,
    stacktrace: true,
    show_sensitive_data_on_connection_error: true,
    pool_size: 15
end

# ------------------------------------------------------------------
# The rest of this file is the standard Phoenix runtime configuration
# executed for all environments and for releases.
# ------------------------------------------------------------------

if System.get_env("PHX_SERVER") do
  config :gitex, GitexWeb.Endpoint, server: true
end

config :gitex, GitexWeb.Endpoint, http: [port: String.to_integer(System.get_env("PORT") || "4000")]

if config_env() == :dev do
  # Reload browser tabs when matching files change.
  config :gitex, GitexWeb.Endpoint,
    live_reload: [
      web_console_logger: true,
      patterns: [
        ~r"priv/static/(?!uploads/).*\.(js|css|png|jpeg|jpg|gif|svg)$",
        ~r"priv/gettext/.*\.po$",
        ~r"lib/gitex_web/router\.ex$",
        ~r"lib/gitex_web/(controllers|live|components)/.*\.(ex|heex)$"
      ]
    ]
end

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :gitex, Gitex.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "15"),
    socket_options: maybe_ipv6

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("RENDER_EXTERNAL_HOSTNAME") || "localhost"

  config :gitex, :dns_cluster_query, System.get_env("DNS_CLUSTER_QUERY")

  config :gitex, GitexWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0}
    ],
    secret_key_base: secret_key_base
end
