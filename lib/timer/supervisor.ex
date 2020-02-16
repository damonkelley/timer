defmodule Timer.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {Registry, keys: :unique, name: Timer.Registry},
      {Registry, keys: :duplicate, name: Timer.Notifications},
      {DynamicSupervisor, strategy: :one_for_one, name: Timer.TaskSupervisor},
      {Timer.Tick, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
