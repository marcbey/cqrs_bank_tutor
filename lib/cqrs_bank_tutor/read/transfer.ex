defmodule CqrsBankTutor.Read.Transfer do
  @moduledoc """
  Read model for transfers.

  Mirrors the status of a transfer workflow for querying in the UI.
  """
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: false}
  schema "transfers" do
    field :source_id, Ecto.UUID
    field :target_id, Ecto.UUID
    field :amount, :decimal
    field :status, :string
    field :started_at, :utc_datetime_usec
    field :finished_at, :utc_datetime_usec
    field :reason, :string
    timestamps(updated_at: false)
  end
end
