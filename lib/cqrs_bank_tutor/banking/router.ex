defmodule CqrsBankTutor.Banking.Router do
  @moduledoc """
  Command router (write side).

  - Maps incoming commands to their target aggregate and identity field.
  - Ensures each aggregate instance has its own event stream via identity.
  - Keeps orchestration concerns out of aggregates (handled by PMs).
  """
  use Commanded.Commands.Router

  alias CqrsBankTutor.Banking.Aggregates.{BankAccount, Transfer}
  alias CqrsBankTutor.Banking.Commands.{
    OpenAccount,
    DepositMoney,
    WithdrawMoney,
    StartTransfer,
    MarkTransferAsCredited
  }

  # Bank accounts are aggregates identified by account_id
  dispatch [OpenAccount, DepositMoney, WithdrawMoney],
    to: BankAccount,
    identity: :account_id

  # Transfers are aggregates identified by transfer_id
  dispatch [StartTransfer, MarkTransferAsCredited],
    to: Transfer,
    identity: :transfer_id
end
