defmodule CqrsBankTutor.Banking.Commands.WithdrawMoney do
  @moduledoc """
  Command: withdraw funds from an account.

  The aggregate guards against overdrafts and emits `MoneyWithdrawn`.
  """
  @enforce_keys [:account_id, :amount]
  defstruct [:account_id, :amount]
end
