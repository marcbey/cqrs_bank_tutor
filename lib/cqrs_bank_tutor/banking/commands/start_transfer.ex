defmodule CqrsBankTutor.Banking.Commands.StartTransfer do
  @moduledoc """
  Command: start a money transfer between two accounts.

  Emits `TransferStarted` in the transfer aggregate and triggers the
  `MoneyTransferPM` saga to coordinate debit and credit steps.
  """
  @enforce_keys [:transfer_id, :source_id, :target_id, :amount]
  defstruct [:transfer_id, :source_id, :target_id, :amount]
end
