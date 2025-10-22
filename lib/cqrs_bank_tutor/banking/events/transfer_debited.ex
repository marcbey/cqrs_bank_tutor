defmodule CqrsBankTutor.Banking.Events.TransferDebited do
  @moduledoc """
  Event: the transfer amount was successfully debited from the source.

  Optional in this tutorial; included to illustrate richer workflows.
  """
  @derive Jason.Encoder
  defstruct [:transfer_id, :source_id, :amount, :at]
end
