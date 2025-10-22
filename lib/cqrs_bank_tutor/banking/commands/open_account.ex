defmodule CqrsBankTutor.Banking.Commands.OpenAccount do
  @moduledoc """
  Command: open a new bank account with an initial balance.

  The aggregate validates invariants (e.g., non-negative initial balance)
  and emits `AccountOpened` on success.
  """
  @enforce_keys [:account_id, :owner, :initial_balance]
  defstruct [:account_id, :owner, :initial_balance]
end
