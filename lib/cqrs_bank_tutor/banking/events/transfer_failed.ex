defmodule CqrsBankTutor.Banking.Events.TransferFailed do
  @moduledoc """
  Event: the transfer could not be completed.

  Use this to record reasons like insufficient funds for tutorial purposes.
  """
  @derive Jason.Encoder
  defstruct [:transfer_id, :reason, :at]
end
