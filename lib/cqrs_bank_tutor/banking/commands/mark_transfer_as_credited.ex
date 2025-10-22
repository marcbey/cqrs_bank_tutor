defmodule CqrsBankTutor.Banking.Commands.MarkTransferAsCredited do
  @moduledoc """
  Command: finalize a transfer after the credit step succeeded.

  Issued by the process manager to mark the end of the transfer workflow.
  """
  @enforce_keys [:transfer_id]
  defstruct [:transfer_id]
end
