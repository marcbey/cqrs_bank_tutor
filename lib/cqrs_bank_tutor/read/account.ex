defmodule CqrsBankTutor.Read.Account do
  @moduledoc """
  Read model for accounts.

  Populated exclusively by projectors from events; never mutated directly
  by user code. Can be rebuilt by replaying the event stream.
  """
  use Ecto.Schema
  @primary_key {:id, :binary_id, autogenerate: false}
  schema "accounts" do
    field :owner, :string
    field :balance, :decimal
    field :opened_at, :utc_datetime_usec
    timestamps(updated_at: false)
  end
end
