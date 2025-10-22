defmodule CqrsBankTutor.EventStore do
  @moduledoc """
  EventStore instance used by Commanded.

  Backed by PostgreSQL, this module provides an append-only event stream
  where domain events are stored and later consumed by process managers and
  projectors. The store is configured under the `:cqrs_bank_tutor` OTP app.
  """
  use EventStore, otp_app: :cqrs_bank_tutor
end
