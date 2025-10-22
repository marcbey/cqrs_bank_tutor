defmodule CqrsBankTutor.Banking.Events.AccountOpened do
  @moduledoc """
  Event: an account has been opened.

  Emitted exactly once per account stream when `OpenAccount` succeeds.
  """
  @derive Jason.Encoder
  defstruct [:account_id, :owner, :initial_balance, :opened_at]
end
