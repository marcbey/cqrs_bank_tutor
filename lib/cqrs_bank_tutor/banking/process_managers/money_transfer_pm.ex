defmodule CqrsBankTutor.Banking.ProcessManagers.MoneyTransferPM do
  @moduledoc """
  Process Manager (Saga) orchestrating a transfer from source to target.

  Flow
  1) On `TransferStarted` -> issue `WithdrawMoney` on source.
  2) On `MoneyWithdrawn` -> issue `DepositMoney` on target.
  3) On `MoneyDeposited` -> issue `MarkTransferAsCredited` to finalize.

  Notes
  - Commands are emitted in reaction to events; no state is stored outside
    of what we derive from applied events.
  - Failure cases (e.g., insufficient funds) can emit a `TransferFailed`
    event or perform compensation.
  """
  use Commanded.ProcessManagers.ProcessManager,
    name: __MODULE__,
    application: CqrsBankTutor.App

  defstruct [:transfer_id, :source_id, :target_id, :amount, status: :init]

  alias CqrsBankTutor.Banking.Commands.{WithdrawMoney, DepositMoney, MarkTransferAsCredited}
  alias CqrsBankTutor.Banking.Events.{TransferStarted, MoneyWithdrawn, MoneyDeposited, TransferFailed, TransferCredited}

  @doc "Correlate events to a transfer instance (prefer event.transfer_id, fallback to metadata.correlation_id)."
  def interested?(%TransferStarted{transfer_id: id}, _metadata), do: {:start, id}
  def interested?(%MoneyWithdrawn{transfer_id: id}, _metadata) when not is_nil(id), do: {:continue, id}
  def interested?(%MoneyDeposited{transfer_id: id}, _metadata) when not is_nil(id), do: {:continue, id}
  def interested?(%MoneyWithdrawn{}, %{correlation_id: id}) when is_binary(id), do: {:continue, id}
  def interested?(%MoneyDeposited{}, %{correlation_id: id}) when is_binary(id), do: {:continue, id}
  def interested?(%TransferCredited{transfer_id: id}, _metadata), do: {:continue, id}
  def interested?(_, _), do: false

  def handle(%__MODULE__{status: :debiting}, %TransferStarted{transfer_id: tid, source_id: src, amount: amt}) do
    %WithdrawMoney{account_id: src, amount: amt, transfer_id: tid}
  end

  def handle(%__MODULE__{} = s, %MoneyWithdrawn{}) do
    %DepositMoney{account_id: s.target_id, amount: s.amount, transfer_id: s.transfer_id}
  end

  def handle(%__MODULE__{} = s, %MoneyDeposited{}) do
    %MarkTransferAsCredited{transfer_id: s.transfer_id}
  end

  # State transitions
  def apply(%__MODULE__{} = s, %TransferStarted{transfer_id: id, source_id: src, target_id: tgt, amount: amt}) do
    %{s | transfer_id: id, source_id: src, target_id: tgt, amount: amt, status: :debiting}
  end

  def apply(%__MODULE__{} = s, %MoneyWithdrawn{}), do: %{s | status: :crediting}
  def apply(%__MODULE__{} = s, %MoneyDeposited{}), do: %{s | status: :finishing}
  def apply(%__MODULE__{} = s, %TransferCredited{}), do: %{s | status: :done}
  def apply(%__MODULE__{} = s, %TransferFailed{}), do: %{s | status: :failed}
end
