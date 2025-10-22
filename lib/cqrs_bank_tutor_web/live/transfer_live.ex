defmodule CqrsBankTutorWeb.TransferLive do
  @moduledoc """
  Transfer detail view backed by the read model.

  Shows the status transitions driven by events and the process manager.
  """
  use CqrsBankTutorWeb, :live_view

  alias CqrsBankTutor.{Repo}
  alias CqrsBankTutor.Read.Transfer

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok, assign(socket, transfer: Repo.get(Transfer, id))}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class={["max-w-2xl mx-auto py-8 space-y-6"]}>
        <h1 class={["text-xl font-semibold"]}>Transfer <%= @transfer.id %></h1>
        <div class={["rounded-md border p-4 space-y-1"]}>
          <div>Amount: €<%= Decimal.to_string(@transfer.amount) %></div>
          <div>Status: <%= @transfer.status %></div>
          <div>From: <%= @transfer.source_id %></div>
          <div>To: <%= @transfer.target_id %></div>
        </div>
      </div>
    </Layouts.app>
    """
  end
end
