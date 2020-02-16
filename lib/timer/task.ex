defmodule Timer.Task do
  use GenServer

  def init(state) do
    Process.send_after(self(), :tick, 1000)

    {:ok, state}
  end

  def start_link(%{name: name} = task) do
    GenServer.start_link(__MODULE__, %{started: false, task: task}, name: via_tuple(name))
  end

  def get(name) do
    GenServer.call(via_tuple(name), :get)
  end

  def begin(name) do
    GenServer.call(via_tuple(name), :begin)
  end

  def handle_call(:get, _from, %{task: task} = state) do
    {:reply, task, state}
  end

  def handle_cast(:begin, state) do
    {:noreply, %{state | started: true}}
  end

  def handle_info(:tick, %{started: true, task: %{duration: duration} = task} = state) do
    tick()
    {:noreply, %{state | task: %{task | duration: duration - 1}}}
  end

  def handle_info(:tick, state) do
    tick()
    {:noreply, state}
  end

  defp tick() do
    Process.send_after(self(), :tick, 1000)
  end

  defp via_tuple(name) do
    {:via, Registry, {Timer.Registry, name}}
  end
end
