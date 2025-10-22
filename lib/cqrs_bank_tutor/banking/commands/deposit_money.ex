defmodule CqrsBankTutor.Banking.Commands.DepositMoney do
  @moduledoc """
  Command: deposit funds into an existing account.

  On success the `BankAccount` emits `MoneyDeposited` with the new balance.
  """
  @enforce_keys [:account_id, :amount]
  defstruct [:account_id, :amount]
end
