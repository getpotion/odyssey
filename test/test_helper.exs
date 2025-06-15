Faker.start()

ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Odyssey.Repo, :manual)

# Start Cachex for tests
Cachex.start_link(:login_tokens)

# Import factory functions
require Odyssey.Factory
require Odyssey.EmailStub

Mox.defmock(Odyssey.Accounts.TwoFactorMock, for: Odyssey.Accounts.TwoFactor.Behaviour)
Mox.defmock(Odyssey.EmailMock, for: Odyssey.Email.Behaviour)
Mox.set_mox_global()
Mox.stub_with(Odyssey.EmailMock, Odyssey.EmailStub)

# Set the email adapter to use our mock
Application.put_env(:odyssey, :email_adapter, Odyssey.EmailMock)
