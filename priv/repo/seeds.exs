alias CqrsBankTutor.App
alias CqrsBankTutor.Repo
alias CqrsBankTutor.Read.Account
alias CqrsBankTutor.Banking.Commands.{OpenAccount, DepositMoney}

# Start the application tree so Commanded + projectors are running
{:ok, _} = Application.ensure_all_started(:cqrs_bank_tutor)

defmodule Seeds do
  def dec(val) when is_binary(val), do: Decimal.new(val)
  def dec(val) when is_integer(val) or is_float(val), do: val |> to_string() |> Decimal.new()

  def create_account(owner, initial_amount) do
    id = Ecto.UUID.generate()

    open = %OpenAccount{account_id: id, owner: owner, initial_balance: dec("0.00")}
    case App.dispatch(open) do
      :ok -> :ok
      {:error, reason} -> raise "OpenAccount failed: #{inspect(reason)}"
    end

    if Decimal.compare(initial_amount, 0) == :gt do
      deposit = %DepositMoney{account_id: id, amount: initial_amount}
      case App.dispatch(deposit) do
        :ok -> :ok
        {:error, reason} -> raise "DepositMoney failed: #{inspect(reason)}"
      end
    end

    id
  end
end

IO.puts("Seeding demo data (accounts)...")

alice = Seeds.create_account("Alice", Seeds.dec("100.00"))
bob   = Seeds.create_account("Bob",   Seeds.dec("50.00"))

# Allow projections to catch up (eventual consistency)
Process.sleep(300)

accounts = Repo.all(Account)

IO.puts("\nAccounts created:")
for a <- accounts do
  IO.puts("- #{a.owner} (#{a.id}): €#{a.balance}")
end

IO.puts("\nTry a transfer in the UI: from Alice to Bob.")

