defmodule CqrsBankTutor.Banking.Projectors.TransfersProjector do
  @moduledoc """
  Projects transfer lifecycle into the `transfers` read table.

  - On `TransferStarted`, create a row with status "debiting".
  - On `TransferCredited`, mark as "done" and set finished_at.
  - On `TransferFailed`, mark as "failed" with a reason.
  """
  use Commanded.Projections.Ecto,
    name: __MODULE__,
    application: CqrsBankTutor.App,
    repo: CqrsBankTutor.Repo

  import Ecto.Query
  alias CqrsBankTutor.Banking.Events.{TransferStarted, TransferCredited, TransferFailed}
  alias CqrsBankTutor.Read.Transfer

  project %TransferStarted{transfer_id: id, source_id: s, target_id: t, amount: amt, started_at: at}, _ do
    Ecto.Multi.insert(multi, :transfer, %Transfer{id: id, source_id: s, target_id: t, amount: dec(amt), status: "debiting", started_at: dt(at)})
  end

  project %TransferCredited{transfer_id: id}, _ do
    Ecto.Multi.update_all(multi, :transfer, from(x in Transfer, where: x.id == ^id), set: [status: "done", finished_at: DateTime.utc_now()])
  end

  project %TransferFailed{transfer_id: id, reason: r}, _ do
    Ecto.Multi.update_all(multi, :transfer, from(x in Transfer, where: x.id == ^id), set: [status: "failed", reason: r, finished_at: DateTime.utc_now()])
  end

  defp dec(%Decimal{} = d), do: d
  defp dec(n) when is_binary(n) or is_integer(n) or is_float(n), do: Decimal.new(n)
  defp dt(%DateTime{} = dt), do: dt
  defp dt(iso) when is_binary(iso) do
    case DateTime.from_iso8601(iso) do
      {:ok, dt, _} -> dt
      _ -> DateTime.utc_now()
    end
  end
end
