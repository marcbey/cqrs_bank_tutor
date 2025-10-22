defmodule CqrsBankTutor.App do
  @moduledoc """
  Commanded application for the write model.

  - Receives commands from the UI or other code via `dispatch/2`.
  - Routes commands to aggregates through `CqrsBankTutor.Banking.Router`.
  - Persists resulting domain events to the EventStore.

  In CQRS/ES, this process encapsulates the write-side behavior and
  consistency rules. The read-side is handled separately by Ecto projectors.
  """
  use Commanded.Application, otp_app: :cqrs_bank_tutor

  router CqrsBankTutor.Banking.Router
end
