defmodule CqrsBankTutor.Repo.Migrations.AddInsertedAtToReadTables do
  use Ecto.Migration

  def up do
    alter table(:accounts) do
      add :inserted_at, :utc_datetime_usec, null: false, default: fragment("(now() at time zone 'utc')")
    end

    alter table(:transfers) do
      add :inserted_at, :utc_datetime_usec, null: false, default: fragment("(now() at time zone 'utc')")
    end
  end

  def down do
    alter table(:accounts) do
      remove :inserted_at
    end

    alter table(:transfers) do
      remove :inserted_at
    end
  end
end

