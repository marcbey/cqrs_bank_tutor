defmodule CqrsBankTutor.Banking.Events.MoneyWithdrawn do
  @moduledoc """
  Event: funds were withdrawn from an account.

  Encodes the resulting balance to keep event handling deterministic.
  """
  @derive Jason.Encoder
  defstruct [:account_id, :amount, :new_balance, :at, :transfer_id]
end
