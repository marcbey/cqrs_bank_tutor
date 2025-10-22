defmodule CqrsBankTutorWeb.DashboardLive do
  @moduledoc """
  Tutorial dashboard showing CQRS in action.

  - Reads from the Ecto projections (read DB).
  - Emits commands to the Commanded app to change state.
  - Demonstrates the separation between write (commands/events) and read (queries).
  """
  use CqrsBankTutorWeb, :live_view

  alias CqrsBankTutor.{Repo}
  alias CqrsBankTutor.Read.{Account, Transfer}
  alias CqrsBankTutor.Banking.Commands.{OpenAccount, StartTransfer}
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    socket =
      socket
      |> stream(:accounts, list_accounts())
      |> stream(:transfers, list_transfers())

    {:ok, socket}
  end

  @impl true
  def handle_event("open_account", %{"owner" => owner, "initial" => initial}, socket) do
    id = Ecto.UUID.generate()
    cmd = %OpenAccount{account_id: id, owner: owner, initial_balance: Decimal.new(initial)}
    :ok = CqrsBankTutor.App.dispatch(cmd)
    {:noreply, refresh(socket)}
  end

  @impl true
  def handle_event("start_transfer", %{"src" => s, "tgt" => t, "amount" => a}, socket) do
    if s == t do
      {:noreply, put_flash(socket, :error, "Source and target must differ")}
    else
      id = Ecto.UUID.generate()
      cmd = %StartTransfer{transfer_id: id, source_id: s, target_id: t, amount: Decimal.new(a)}
      case CqrsBankTutor.App.dispatch(cmd) do
        :ok -> {:noreply, refresh(socket)}
        {:error, reason} -> {:noreply, put_flash(socket, :error, inspect(reason))}
      end
    end
  end

  defp list_accounts, do: Repo.all(Account)
  defp list_transfers, do: Repo.all(from(t in Transfer, order_by: [desc: t.inserted_at], limit: 10))
  defp refresh(socket) do
    socket
    |> stream(:accounts, list_accounts(), reset: true)
    |> stream(:transfers, list_transfers(), reset: true)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class={["max-w-5xl mx-auto py-8 space-y-8"]}>
        <h1 class={["text-2xl font-semibold"]}>Dashboard</h1>
        <div class={["grid md:grid-cols-2 gap-6"]}>
          <div class={["space-y-4"]}>
            <h2 class={["text-xl font-medium"]}>Accounts</h2>
            <div id="accounts" phx-update="stream" class={["divide-y divide-zinc-200 rounded-md border"]}>
              <div :for={{id, a} <- @streams.accounts} id={id} class={["p-4 flex items-center justify-between"]}>
                <div>
                  <div class={["font-medium"]}>Owner: <%= a.owner %></div>
                  <div class={["text-sm text-zinc-600"]}>Balance: €<%= a.balance %></div>
                </div>
                <.link navigate={~p"/accounts/#{a.id}"} class={["text-zinc-700 hover:underline"]}>View</.link>
              </div>
            </div>
            <form phx-submit="open_account" class="space-y-2">
              <.input name="owner" label="Owner" required />
              <.input name="initial" label="Initial Balance (EUR)" type="number" step="0.01" value="0.00" />
              <.button class="mt-2">Open account</.button>
            </form>
          </div>
          <div class={["space-y-4"]}>
            <h2 class={["text-xl font-medium"]}>Transfers (latest)</h2>
            <div id="transfers" phx-update="stream" class={["divide-y divide-zinc-200 rounded-md border"]}>
              <div class={["hidden only:block p-4 text-sm text-zinc-600"]}>No transfers yet</div>
              <div :for={{id, t} <- @streams.transfers} id={id} class={["p-4 flex items-center justify-between"]}>
                <div>
                  <div class={["font-medium"]}>€<%= t.amount %> • <%= t.status %></div>
                  <div class={["text-sm text-zinc-600"]}>from <%= t.source_id %> to <%= t.target_id %></div>
                </div>
                <.link navigate={~p"/transfers/#{t.id}"} class={["text-zinc-700 hover:underline"]}>View</.link>
              </div>
            </div>
            <form phx-submit="start_transfer" class="space-y-2">
              <.input name="src" label="Source Account ID" required />
              <.input name="tgt" label="Target Account ID" required />
              <.input name="amount" label="Amount (EUR)" type="number" step="0.01" required />
              <.button class="mt-2">Start transfer</.button>
            </form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
