defmodule CqrsBankTutorWeb.AccountLive do
  @moduledoc """
  Account detail view backed by the read model.

  Demonstrates dispatching `DepositMoney` and `WithdrawMoney` commands and
  observing eventual consistency as projectors update the read record.
  """
  use CqrsBankTutorWeb, :live_view

  alias CqrsBankTutor.{Repo}
  alias CqrsBankTutor.Read.Account
  alias CqrsBankTutor.Banking.Commands.{DepositMoney, WithdrawMoney}

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, assign(socket, account: Repo.get(Account, id))}
  end

  @impl true
  def handle_event("deposit", %{"amount" => a}, %{assigns: %{account: acc}} = socket) do
    cmd = %DepositMoney{account_id: acc.id, amount: Decimal.new(a)}
    case CqrsBankTutor.App.dispatch(cmd) do
      :ok -> {:noreply, assign(socket, account: Repo.get!(Account, acc.id))}
      {:error, reason} -> {:noreply, put_flash(socket, :error, inspect(reason))}
    end
  end

  def handle_event("withdraw", %{"amount" => a}, %{assigns: %{account: acc}} = socket) do
    cmd = %WithdrawMoney{account_id: acc.id, amount: Decimal.new(a)}
    case CqrsBankTutor.App.dispatch(cmd) do
      :ok -> {:noreply, assign(socket, account: Repo.get!(Account, acc.id))}
      {:error, reason} -> {:noreply, put_flash(socket, :error, inspect(reason))}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-2xl mx-auto py-8 space-y-6">
        <h1 class="text-xl font-semibold">Account <%= @account.id %></h1>
        <div class="rounded-md border p-4 space-y-1">
          <div>Owner: <b><%= @account.owner %></b></div>
          <div>Balance: €<%= @account.balance %></div>
        </div>
        <div class="grid sm:grid-cols-2 gap-4">
          <form phx-submit="deposit" class="space-y-2">
            <.input name="amount" label="Deposit EUR" type="number" step="0.01" />
            <.button>Deposit</.button>
          </form>
          <form phx-submit="withdraw" class="space-y-2">
            <.input name="amount" label="Withdraw EUR" type="number" step="0.01" />
            <.button>Withdraw</.button>
          </form>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
