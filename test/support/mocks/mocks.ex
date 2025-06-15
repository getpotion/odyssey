defmodule Odyssey.Mocks do
  @moduledoc """
  Provides mock implementations for testing purposes.
  """
  Mox.defmock(Odyssey.AccountsMock, for: Odyssey.Accounts.Behaviour)
end
