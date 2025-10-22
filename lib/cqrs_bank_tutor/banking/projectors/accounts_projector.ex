defmodule CqrsBankTutor.Banking.Projectors.AccountsProjector do
  @moduledoc """
  Projects account-related events into the `accounts` read table.

  - Inserts a row on `AccountOpened`.
  - Updates the balance on `MoneyDeposited` and `MoneyWithdrawn`.
  - Uses Ecto.Multi for idempotent, transactional updates.
  """
  use Commanded.Projections.Ecto,
    name: __MODULE__,
    application: CqrsBankTutor.App,
    repo: CqrsBankTutor.Repo

  import Ecto.Query
  alias CqrsBankTutor.Banking.Events.{AccountOpened, MoneyDeposited, MoneyWithdrawn}
  alias CqrsBankTutor.Read.Account

  project %AccountOpened{account_id: id, owner: owner, initial_balance: bal, opened_at: at}, _metadata do
    Ecto.Multi.insert(multi, :account, %Account{id: id, owner: owner, balance: dec(bal), opened_at: dt(at)})
  end

  project %MoneyDeposited{account_id: id, new_balance: nb}, _metadata do
    Ecto.Multi.update_all(multi, :account, from(a in Account, where: a.id == ^id), set: [balance: dec(nb)])
  end

  project %MoneyWithdrawn{account_id: id, new_balance: nb}, _metadata do
    Ecto.Multi.update_all(multi, :account, from(a in Account, where: a.id == ^id), set: [balance: dec(nb)])
  end

  defp dec(%Decimal{} = d), do: d
  defp dec(n) when is_binary(n) or is_integer(n) or is_float(n), do: Decimal.new(n)
  defp dt(%DateTime{} = dt), do: dt
  defp dt(iso) when is_binary(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end
end
