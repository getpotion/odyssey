import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :odyssey, Odyssey.Repo,
  adapter: Ecto.Adapters.SQLite3,
  database: "test/support/odyssey_test.sqlite3",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 5,
  timeout: 60_000,
  connect_timeout: 60_000,
  retry_interval: 5_000,
  max_retries: 5,
  priv: "priv/repo",
  migration_timestamps: [type: :utc_datetime]

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :odyssey, OdysseyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "fKyDWSorfOiwlujMJVD6r1SEueGnPZ19txck5auabgjBA4B+Uh0foDTv6JDySWo6",
  server: false

# In test we don't send emails
config :odyssey, Odyssey.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

config :odyssey, OdysseyWeb, domain: "localhost"
config :odyssey, :email_adapter, Odyssey.EmailMock
config :odyssey, :accounts, Odyssey.AccountsMock
