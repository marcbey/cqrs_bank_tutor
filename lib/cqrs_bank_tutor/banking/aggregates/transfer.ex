defmodule CqrsBankTutor.Banking.Aggregates.Transfer do
  @moduledoc """
  Transfer aggregate emitting lifecycle events.

  The actual debit/credit work is orchestrated by the process manager.
  This aggregate records the start and completion of a transfer.
  """
  defstruct [:transfer_id, :source_id, :target_id, :amount, status: :init]

  alias __MODULE__
  alias CqrsBankTutor.Banking.Commands.{StartTransfer, MarkTransferAsCredited}
  alias CqrsBankTutor.Banking.Events.{TransferStarted, TransferCredited}

  @doc "Emit TransferStarted when a new transfer is initiated."
  def execute(%Transfer{status: :init}, %StartTransfer{transfer_id: id, source_id: s, target_id: t, amount: a}) do
    %TransferStarted{transfer_id: id, source_id: s, target_id: t, amount: a, started_at: DateTime.utc_now()}
  end

  @doc "Emit TransferCredited only after the PM has credited the target."
  def execute(%Transfer{status: :finishing} = s, %MarkTransferAsCredited{}) do
    %TransferCredited{transfer_id: s.transfer_id, target_id: s.target_id, amount: s.amount, at: DateTime.utc_now()}
  end

  def execute(%Transfer{}, %MarkTransferAsCredited{}), do: {:error, :not_ready}

  # Apply
  def apply(%Transfer{} = s, %TransferStarted{transfer_id: id, source_id: src, target_id: tgt, amount: amt}) do
    %Transfer{s | transfer_id: id, source_id: src, target_id: tgt, amount: amt, status: :debiting}
  end

  def apply(%Transfer{} = s, %TransferCredited{}), do: %Transfer{s | status: :done}
end
