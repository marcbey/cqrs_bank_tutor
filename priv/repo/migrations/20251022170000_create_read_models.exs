defmodule CqrsBankTutor.Repo.Migrations.CreateReadModels do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :owner, :text, null: false
      add :balance, :decimal, precision: 20, scale: 2, null: false
      add :opened_at, :utc_datetime_usec
    end

    create table(:transfers, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :source_id, :uuid, null: false
      add :target_id, :uuid, null: false
      add :amount, :decimal, precision: 20, scale: 2, null: false
      add :status, :text, null: false
      add :started_at, :utc_datetime_usec
      add :finished_at, :utc_datetime_usec
      add :reason, :text
    end

    create index(:transfers, [:source_id])
    create index(:transfers, [:target_id])
  end
end

