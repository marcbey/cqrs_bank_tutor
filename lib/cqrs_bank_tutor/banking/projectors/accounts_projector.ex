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
    Ecto.Multi.insert(multi, :account, %Account{id: id, owner: owner, balance: bal, opened_at: at})
  end

  project %MoneyDeposited{account_id: id, new_balance: nb}, _metadata do
    Ecto.Multi.update_all(multi, :account, from(a in Account, where: a.id == ^id), set: [balance: nb])
  end

  project %MoneyWithdrawn{account_id: id, new_balance: nb}, _metadata do
    Ecto.Multi.update_all(multi, :account, from(a in Account, where: a.id == ^id), set: [balance: nb])
  end
end
