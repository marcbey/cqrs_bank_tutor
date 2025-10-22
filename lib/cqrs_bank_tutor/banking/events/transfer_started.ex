defmodule CqrsBankTutor.Banking.Events.TransferStarted do
  @moduledoc """
  Event: a transfer workflow has started.

  The `MoneyTransferPM` listens for this event to orchestrate debit/credit.
  """
  @derive Jason.Encoder
  defstruct [:transfer_id, :source_id, :target_id, :amount, :started_at]
end
