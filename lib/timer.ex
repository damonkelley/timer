defmodule Timer do
  use Application

  def start(_type, _args) do
    Timer.Supervisor.start_link(name: Timer.Supervisor)
  end

  def add(task, type \\ Timer.Task) do
    {:ok, _pid} = DynamicSupervisor.start_child(Timer.TaskSupervisor, {type, task})

    {:ok, [task]}
  end

  def begin(name) do
    GenServer.call(via(name), :begin)
  end

  def show do
    names = Registry.select(Timer.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])

    names
    |> Enum.map(&lookup/1)
    |> Enum.reverse()
  end

  defp lookup(name) do
    GenServer.call(via(name), :get)
  end

  defp via(name) do
    {:via, Registry, {Timer.Registry, name}}
  end
end
