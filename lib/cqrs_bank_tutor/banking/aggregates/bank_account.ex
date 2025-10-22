defmodule CqrsBankTutor.Banking.Aggregates.BankAccount do
  @moduledoc """
  Aggregate root for bank accounts.

  Responsibilities
  - Enforce the invariant: balance must never go below zero.
  - Transform commands into domain events (execute functions).
  - Evolve state from events (apply functions).

  Tutorial tips
  - Execute functions must be pure and decision-focused.
  - Apply functions must be pure, deterministic state transitions.
  - Monetary amounts are normalized to EUR with two decimals.
  """
  defstruct [:account_id, :owner, balance: Decimal.new("0.00"), opened?: false]

  alias __MODULE__
  alias CqrsBankTutor.Banking.Commands.{OpenAccount, DepositMoney, WithdrawMoney}
  alias CqrsBankTutor.Banking.Events.{AccountOpened, MoneyDeposited, MoneyWithdrawn}

  def execute(%BankAccount{opened?: false}, %OpenAccount{account_id: id, owner: owner, initial_balance: amt}) do
    amt = normalize!(amt)
    if Decimal.compare(amt, Decimal.new(0)) == :lt do
      {:error, :negative_initial_balance}
    else
      %AccountOpened{account_id: id, owner: owner, initial_balance: amt, opened_at: now()}
    end
  end

  def execute(%BankAccount{opened?: true}, %OpenAccount{}), do: {:error, :already_opened}

  def execute(%BankAccount{opened?: true} = s, %DepositMoney{amount: amt}) do
    amt = normalize!(amt)
    if non_positive?(amt) do
      {:error, :non_positive_amount}
    else
      %MoneyDeposited{account_id: s.account_id, amount: amt, new_balance: Decimal.add(s.balance, amt), at: now()}
    end
  end

  def execute(%BankAccount{opened?: true, balance: bal} = s, %WithdrawMoney{amount: amt}) do
    amt = normalize!(amt)
    cond do
      non_positive?(amt) -> {:error, :non_positive_amount}
      Decimal.compare(bal, amt) == :lt -> {:error, :insufficient_funds}
      true -> %MoneyWithdrawn{account_id: s.account_id, amount: amt, new_balance: Decimal.sub(bal, amt), at: now()}
    end
  end

  # Event appliers (state evolution)
  def apply(%BankAccount{} = s, %AccountOpened{account_id: id, owner: o, initial_balance: amt}) do
    %BankAccount{s | account_id: id, owner: o, balance: amt, opened?: true}
  end

  def apply(%BankAccount{} = s, %MoneyDeposited{new_balance: nb}), do: %BankAccount{s | balance: nb}
  def apply(%BankAccount{} = s, %MoneyWithdrawn{new_balance: nb}), do: %BankAccount{s | balance: nb}

  # Helpers
  defp normalize!(%Decimal{} = d), do: Decimal.round(d, 2)
  defp normalize!(n) when is_integer(n) or is_float(n) or is_binary(n), do: n |> Decimal.new() |> normalize!()
  defp non_positive?(d), do: Decimal.compare(d, Decimal.new(0)) in [:eq, :lt]
  defp now, do: DateTime.utc_now()
end
