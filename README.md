# CqrsBankTutor

Tiny Phoenix + Commanded app to teach CQRS, Event Sourcing, and DDD by implementing bank accounts and transfers.

## Getting Started

Prerequisites
- Elixir ≥ 1.17, Erlang/OTP ≥ 27
- PostgreSQL ≥ 14 (defaults: `postgres:postgres@localhost`)

1) Setup (installs deps, assets, creates/initializes EventStore and read DB):
- `mix setup`

2) Run the server:
- `mix phx.server`
- Visit http://localhost:4000

3) Configure databases (optional):
- EventStore env: `PGUSER`, `PGPASSWORD`, `PGDATABASE`, `PGHOST`, `PGPORT`
- Read DB env: `DATABASE_URL` (e.g., `ecto://postgres:postgres@localhost/cqrs_bank_tutor_read`)

Learn the architecture and flows in `docs/overview.md`.

## Demo Data (seeds)

- With the server stopped, run: `mix demo`
- This opens two accounts:
  - Alice with €100.00
  - Bob with €50.00
- Start the server and try a transfer from Alice → Bob.

## Diagrams

High‑level flow

```
UI (LiveView)
   │  sends command
   ▼
Commanded App (Router → Aggregate)
   │  emits event(s)
   ▼
EventStore (append‑only)
   │  subscribes
   ├────────► Process Manager (saga) ──► emits more commands
   │                                      (e.g., withdraw → deposit → finalize)
   │  subscribes
   ▼
Projectors (Ecto)
   │  write
   ▼
Read DB (Ecto schemas)
   ▲
   │  queries
UI (LiveView)
```

Transfer happy path

```
StartTransfer ──► TransferStarted ──► PM issues WithdrawMoney
                                     └─event→ MoneyWithdrawn ──► PM issues DepositMoney
                                                              └─event→ MoneyDeposited ──► PM issues MarkTransferAsCredited
                                                                                           └─event→ TransferCredited
```

See more in `docs/overview.md` and the `docs/cheat_sheet.md` quick reference.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
