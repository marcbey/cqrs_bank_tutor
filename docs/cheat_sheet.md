# CQRS / ES / DDD — Cheat Sheet

Fast, opinionated reference for this project’s patterns and files.

## Core Concepts

- Command: Intent to change state (imperative). Example: `StartTransfer`.
- Event: Fact after success (past tense). Example: `TransferStarted`.
- Aggregate: Consistency boundary; decides and enforces invariants.
- Process Manager (Saga): Orchestrates cross‑aggregate workflows.
- Projection: Read model maintained from events for efficient queries.

## Where Things Live (files)

- Router (write): `lib/cqrs_bank_tutor/banking/router.ex`
- Aggregates: `lib/cqrs_bank_tutor/banking/aggregates/*.ex`
- Commands: `lib/cqrs_bank_tutor/banking/commands/*.ex`
- Events: `lib/cqrs_bank_tutor/banking/events/*.ex`
- Process Manager: `lib/cqrs_bank_tutor/banking/process_managers/money_transfer_pm.ex`
- Projectors: `lib/cqrs_bank_tutor/banking/projectors/*.ex`
- Read schemas: `lib/cqrs_bank_tutor/read/*.ex`
- EventStore module: `lib/cqrs_bank_tutor/event_store.ex`
- Commanded application: `lib/cqrs_bank_tutor/app.ex`

## Aggregate Rules (BankAccount example)

- Use `execute/2` for decisions (command → event | {:error, reason}).
- Use `apply/2` for state evolution (event → new state).
- Enforce invariants here (e.g., balance never below zero).
- Keep functions pure; no DB or side effects.

## Process Manager Rules (MoneyTransferPM)

- React to events; issue new commands to other aggregates.
- Keep only minimal state derived from applied events.
- Don’t perform long‑running blocking work; just orchestrate.

## Projector Rules (Ecto projections)

- Subscribe to events; update read tables via `Ecto.Multi`.
- Make handlers idempotent; safe to replay events.
- Read models are for queries/UI only; never mutate them directly.

## Do / Don’t

- Do model commands/events in ubiquitous language (owner, account, transfer).
- Do keep write model (aggregates) free from query concerns.
- Do keep projectors simple and idempotent.
- Don’t query aggregates in the UI; always read from projections.
- Don’t put business invariants in controllers or DB triggers; keep them in aggregates.

## Typical Flows

- Open account
  - Command: `OpenAccount` → Event: `AccountOpened` → Project `accounts` row

- Deposit / Withdraw
  - Commands: `DepositMoney` / `WithdrawMoney` → Events: `MoneyDeposited` / `MoneyWithdrawn` → Update balance in `accounts`

- Transfer (happy path)
  - `StartTransfer` → `TransferStarted`
  - PM issues `WithdrawMoney` → `MoneyWithdrawn`
  - PM issues `DepositMoney` → `MoneyDeposited`
  - PM issues `MarkTransferAsCredited` → `TransferCredited`

## Eventual Consistency Tips

- UI may see stale data for milliseconds while projectors catch up.
- Show “updating…” states or optimistic UI updates.
- For confirmations, listen for projector updates or reload after a short delay.

## Testing Pointers

- Aggregates: Given events … when command … then expect events/state.
- PM: Publish events and assert emitted follow‑up commands or resulting events.
- Projectors: Insert events, run projector, assert read rows.
- LiveView: Simulate actions, wait briefly, assert projection changes.

## Handy Commands

- Provision & compile: `mix setup`
- Seed demo data: `mix demo`
- Run server: `mix phx.server` (http://localhost:4000)

## When to Emit TransferFailed (exercise)

- If `WithdrawMoney` fails with `{:error, :insufficient_funds}`, decide how to record that:
  - Option A: UI catches error and dispatches a special command to emit `TransferFailed`.
  - Option B: PM intercepts failure via error routing and emits `TransferFailed`.
- Update `TransfersProjector` to store `status: "failed"` and a `reason`.

