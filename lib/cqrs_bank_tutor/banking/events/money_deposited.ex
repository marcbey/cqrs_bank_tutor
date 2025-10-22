defmodule CqrsBankTutor.Banking.Events.MoneyDeposited do
  @moduledoc """
  Event: funds were deposited into an account.

  Carries the new balance to simplify projection logic.
  """
  @derive Jason.Encoder
  defstruct [:account_id, :amount, :new_balance, :at]
end
