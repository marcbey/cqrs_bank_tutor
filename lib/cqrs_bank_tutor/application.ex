defmodule CqrsBankTutor.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CqrsBankTutorWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:cqrs_bank_tutor, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: CqrsBankTutor.PubSub},
      # Read-side Repo
      CqrsBankTutor.Repo,
      # Commanded application (write model)
      CqrsBankTutor.App,
      # Process manager
      CqrsBankTutor.Banking.ProcessManagers.MoneyTransferPM,
      # Projections
      CqrsBankTutor.Banking.Projectors.AccountsProjector,
      CqrsBankTutor.Banking.Projectors.TransfersProjector,
      # Start to serve requests, typically the last entry
      CqrsBankTutorWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: CqrsBankTutor.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    CqrsBankTutorWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
