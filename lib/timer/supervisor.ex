defmodule Timer.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Registry, keys: :unique, name: Timer.Registry},
      {DynamicSupervisor, strategy: :one_for_one, name: Timer.TaskSupervisor}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
