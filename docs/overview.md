# CQRSBankTutor — Architecture Overview (Beginner Friendly)

This project is a tiny, end‑to‑end example of CQRS, Event Sourcing, and DDD using:

- Commanded (write model)
- EventStore (PostgreSQL‑backed event store)
- Ecto (read model projections)
- Phoenix LiveView (UI)

It’s intentionally small and focused to help you learn the core patterns with a concrete, working app. If you are new to these concepts, start with the Quick Definitions and Big Picture sections below.

---

## Quick Definitions

- CQRS (Command Query Responsibility Segregation)
  - Split write operations (commands that change state) from read operations (queries that return state). Each side can be modeled and scaled independently.

- Event Sourcing (ES)
  - Instead of storing rows that are overwritten, store an append‑only log of events (facts) describing what happened. Current state = fold/apply all events.

- Domain‑Driven Design (DDD)
  - Model software around the business domain. Use ubiquitous language (shared domain terms), identify aggregates (consistency boundaries), and encode invariants.

Tip: Commands are intentions (“Withdraw 10€”); Events are facts (“10€ withdrawn”).

---

## Why CQRS + Event Sourcing?

- Separate write concerns (commands, invariants, domain decisions) from read concerns (queries, UX‑optimized schemas).
- Persist facts (events) rather than mutating rows; you can rebuild projections any time.
- Express business logic in an event‑driven, auditable way.

---

## Big Picture

Imagine a ledger:

    UI → Command → Aggregate (decide) → Event → EventStore
                                       ↓
                  Process Manager (orchestrate cross‑aggregate workflows)
                                       ↓
                                Projectors (build read tables)
                                       ↓
                                       UI (queries)

Writes emit immutable events. Readers subscribe and build query‑friendly tables. The UI reads from those tables (eventual consistency) and sends new commands to make changes.

---

## System Map (Where things live)

Write side (Commanded):
- Application: `lib/cqrs_bank_tutor/app.ex`
- Router: `lib/cqrs_bank_tutor/banking/router.ex`
- Aggregates:
  - BankAccount: `lib/cqrs_bank_tutor/banking/aggregates/bank_account.ex`
  - Transfer: `lib/cqrs_bank_tutor/banking/aggregates/transfer.ex`
- Commands: `lib/cqrs_bank_tutor/banking/commands/*.ex`
- Events: `lib/cqrs_bank_tutor/banking/events/*.ex`
- Process Manager (Saga): `lib/cqrs_bank_tutor/banking/process_managers/money_transfer_pm.ex`
- EventStore config: `lib/cqrs_bank_tutor/event_store.ex`, `config/config.exs`

Read side (Ecto):
- Repo: `lib/cqrs_bank_tutor/repo.ex`
- Read schemas: `lib/cqrs_bank_tutor/read/*.ex`
- Projectors: `lib/cqrs_bank_tutor/banking/projectors/*.ex`
- Migration: `priv/repo/migrations/*_create_read_models.exs`

UI (Phoenix LiveView):
- Routes: `lib/cqrs_bank_tutor_web/router.ex`
- Dashboard: `lib/cqrs_bank_tutor_web/live/dashboard_live.ex`
- Account detail: `lib/cqrs_bank_tutor_web/live/account_live.ex`
- Transfer detail: `lib/cqrs_bank_tutor_web/live/transfer_live.ex`

Supervision: `lib/cqrs_bank_tutor/application.ex`

---

## End‑to‑End Flow (Happy Path)

1) A user action triggers a command from LiveView
   - Example: “Open account” posts `OpenAccount{account_id, owner, initial_balance}` via `CqrsBankTutor.App.dispatch/2`.

2) Commanded routes the command to an aggregate
   - `BankAccount` handles `OpenAccount` and emits `AccountOpened` if invariants pass.

3) Events are appended to EventStore
   - The write model is persisted as an append‑only stream (per aggregate identity).

4) Process managers and projectors subscribe and react
   - `MoneyTransferPM` orchestrates multi‑aggregate workflows (withdraw → deposit → finalize).
   - Ecto projectors update read tables (`accounts`, `transfers`).

5) LiveView queries the read DB
   - UI always reads from projections (eventually consistent).

---

## Write Model Essentials (Aggregates)

- Aggregates are pure decision engines:
  - `execute/2` (command → event | error)
  - `apply/2` (event → new state)
- Invariants live in aggregates (e.g., balance never below zero).
- Monetary values are normalized to EUR with 2 decimals (`Decimal`).

Files to study:
- `bank_account.ex`: non‑negative initial balance; no overdrafts.
- `transfer.ex`: records transfer start and completion; the saga drives the steps.
- `money_transfer_pm.ex`: reacts to `TransferStarted` → issues `WithdrawMoney`; reacts to `MoneyWithdrawn` → issues `DepositMoney`; reacts to `MoneyDeposited` → issues `MarkTransferAsCredited`.

---

## Read Model Projections (Queries)

- `AccountsProjector` upserts rows on account events.
- `TransfersProjector` tracks workflow status and timestamps.
- These run under supervision and are idempotent (safe to replay).

Tables (see migration):
- `accounts(id uuid, owner text, balance decimal(20,2), opened_at timestamptz)`
- `transfers(id uuid, source_id uuid, target_id uuid, amount decimal(20,2), status text, started_at timestamptz, finished_at timestamptz, reason text)`

---

## Eventual Consistency (What it is and how to handle it)

- After you dispatch a command, the event is stored immediately, but the read tables update asynchronously.
- The UI might show slightly stale data until projectors catch up; this is usually milliseconds.
- Patterns to keep UX smooth:
  - Optimistic UI (assume success, update UI immediately, reconcile if projector differs)
  - Show transient “updating…” badges
  - For critical confirmations, read from the write model by reloading the aggregate or subscribe to projector notifications

---

## Why Not Just CRUD? (Mental model)

- CRUD overwrites state; you lose the “how did we get here?” story. ES keeps the full history.
- CQRS lets you model reads separately, so you don’t contort schemas to fit both OLTP and reporting needs.
- Aggregates let you put invariants where they belong (e.g., “no overdrafts” inside BankAccount), not scattered across controllers/DB triggers.

---

## Where Do Things Go? (Checklist)

- Validate business invariants? In the aggregate (execute/2)
- Persist a fact? Emit an event from the aggregate; Commanded app stores it
- Coordinate multiple aggregates? Process Manager (saga)
- Build/read UI data? Projectors and Ecto schemas (read side)
- Cross‑cutting validation (shape of params)? Before building the command (UI/command builder)

---

## Common Questions (FAQ)

- Q: Do I read state from aggregates in the UI?
  - A: No. UI reads from projections (read DB). Aggregates are for decisions only.

- Q: How do I update the read DB?
  - A: You don’t directly. Projectors listen to events and update read tables.

- Q: What if a projector runs twice?
  - A: Make handlers idempotent. Using Ecto.Multi with WHERE conditions keeps updates safe.

- Q: How do I handle failures (e.g., insufficient funds)?
  - A: Aggregates return {:error, reason}. You can emit a failure event via the PM or UI to keep a complete audit trail.

- Q: Can I change event structure later?
  - A: Favor additive changes. For breaking changes, use versioned events or upcasters (out of scope for this tutorial but worth researching).

---

## Configuration Notes

- EventStore is configured under the app namespace:
  - `config :cqrs_bank_tutor, CqrsBankTutor.EventStore, ...`
- Commanded application points to EventStore:
  - `config :cqrs_bank_tutor, CqrsBankTutor.App, event_store: [adapter: Commanded.EventStore.Adapters.EventStore, event_store: CqrsBankTutor.EventStore]`
- Read Repo configured in `config/runtime.exs`.

---

## Running the App

1) Provision databases and compile:

   - `mix setup`

   This runs: deps install, assets setup, EventStore create/init, `ecto.create`, and `ecto.migrate`.

2) Start the server:

   - `mix phx.server`
   - Visit http://localhost:4000

3) Try the flows:
   - Open two accounts (Alice/Bob) with initial balances.
   - Start a transfer from Alice → Bob.
   - Watch the transfer status and updated balances.

---

## Failure Paths (for learning)

- If a withdrawal exceeds balance, the aggregate returns `{:error, :insufficient_funds}`.
- You can extend the PM/UI to emit `TransferFailed{reason}` and project it to the read model (exercise below).

---

## Exercises (Guided TODOs)

1) Emit TransferFailed on debit error
   - Where: `MoneyTransferPM` (on command failure) and/or UI fallback.
   - Update `TransfersProjector` to persist failure reason and timestamp.

2) Write aggregate tests
   - Validate `OpenAccount`, `DepositMoney`, `WithdrawMoney` → events and state.

3) Replay projections
   - Drop the read DB, re‑run `ecto.create` + `ecto.migrate`, then restart the app. Projectors should rebuild state from EventStore.

4) List recent events in the UI
   - Build a simple LiveView that fetches and shows recent events for an account’s stream.

5) Snapshots (optional)
   - Research Commanded snapshots to speed up large streams; add a snapshot policy to `BankAccount`.

---

## Testing Tips

- Unit test aggregates: assert command → event(s) decisions and event → state transitions.
- Integration test process manager flows: publish events and assert emitted commands or resulting events.
- Projector tests: seed events, run projector, assert read rows.
- LiveView tests: simulate user actions, assert reads update after a short wait.

---

## Troubleshooting

- EventStore init
  - If `mix event_store.create` warns about event stores, ensure `config :cqrs_bank_tutor, event_stores: [CqrsBankTutor.EventStore]` is set and/or pass `-e CqrsBankTutor.EventStore`.

- DB credentials
  - Defaults assume `postgres:postgres@localhost`. Override via `PG*` env vars (EventStore) and `DATABASE_URL` (read DB).

- Projector subscriptions
  - Check logs for “has successfully subscribed to event store”. If missing, ensure EventStore is reachable and migrations ran.

---

## Glossary

- Aggregate: boundary that enforces invariants (e.g., `BankAccount`).
- Command: intent to change the domain (e.g., `StartTransfer`).
- Event: fact about something that happened (e.g., `MoneyWithdrawn`).
- Process Manager (Saga): coordinates cross‑aggregate workflows.
- Projection: read model derived from events (rebuildable).
- Consistency: write side is strongly consistent; reads are eventually consistent.

---

## References

- Commanded: https://github.com/commanded/commanded
- EventStore: https://github.com/commanded/eventstore
- Phoenix LiveView: https://hexdocs.pm/phoenix_live_view
- Decimal: https://hexdocs.pm/decimal
