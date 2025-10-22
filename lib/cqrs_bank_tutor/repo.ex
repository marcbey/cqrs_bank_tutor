defmodule CqrsBankTutor.Repo do
  @moduledoc """
  Read-side Ecto repository.

  Projections write into a separate read database optimized for queries.
  It can be rebuilt by replaying events from the EventStore at any time.
  """
  use Ecto.Repo,
    otp_app: :cqrs_bank_tutor,
    adapter: Ecto.Adapters.Postgres
end
