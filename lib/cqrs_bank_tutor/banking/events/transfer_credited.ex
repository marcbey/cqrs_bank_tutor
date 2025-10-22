defmodule CqrsBankTutor.Banking.Events.TransferCredited do
  @moduledoc """
  Event: the transfer amount was credited to the target account.

  Emitted by the `Transfer` aggregate when the PM finalizes the workflow.
  """
  @derive Jason.Encoder
  defstruct [:transfer_id, :target_id, :amount, :at]
end
